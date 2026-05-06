import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../models/type_produit.dart';

// CRUD complet pour les types de produits
// Toutes ces routes nécessitent d'être authentifié (authMiddleware appliqué dans server.dart)

Response _forbidden() => Response.forbidden(
  '{"erreur": "Accès réservé à l\'administrateur"}',
  headers: {'content-type': 'application/json'},
);

Router typeProduitRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // ─── GET /types ─────────────────────────────────────────────────────────────
  // Retourne la liste de tous les types de produits
  router.get('/', (Request req) {
    final rows = db.select('SELECT * FROM types_produits ORDER BY nom;');
    // rows est une List<Row> → on la convertit en List<Map> → puis en JSON
    final types = rows.map((r) => TypeProduit.fromMap(r).toMap()).toList();
    return Response.ok(
      jsonEncode(types),
      headers: {'content-type': 'application/json'},
    );
  });

  // ─── GET /types/:id ──────────────────────────────────────────────────────────
  // Retourne un seul type par son identifiant
  router.get('/<id>', (Request req, String id) {
    final rows = db.select(
      'SELECT * FROM types_produits WHERE id = ?;',
      [int.parse(id)],
    );
    if (rows.isEmpty) {
      return Response.notFound(
        '{"erreur": "Type introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(TypeProduit.fromMap(rows.first).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // ─── POST /types ─────────────────────────────────────────────────────────────
  // Crée un nouveau type de produit
  router.post('/', (Request req) async {
    if (req.context['role'] != 'admin') return _forbidden();
    final body = await req.readAsString();
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: '{"erreur": "JSON invalide"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final nom = data['nom'] as String?;
    if (nom == null || nom.trim().isEmpty) {
      return Response.badRequest(
        body: '{"erreur": "Le champ nom est requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    db.execute(
      'INSERT INTO types_produits (nom, description) VALUES (?, ?)',
      [nom.trim(), data['description']],
    );

    // lastInsertRowId : l'id auto-incrémenté du nouvel enregistrement
    final newId = db.lastInsertRowId;
    final rows = db.select(
      'SELECT * FROM types_produits WHERE id = ?;',
      [newId],
    );

    // 201 Created avec le nouvel objet
    return Response(
      201,
      body: jsonEncode(TypeProduit.fromMap(rows.first).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // ─── PUT /types/:id ──────────────────────────────────────────────────────────
  // Modifie un type existant (remplacement complet)
  router.put('/<id>', (Request req, String id) async {
    if (req.context['role'] != 'admin') return _forbidden();
    final body = await req.readAsString();
    late Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return Response.badRequest(
        body: '{"erreur": "JSON invalide"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final nom = data['nom'] as String?;
    if (nom == null || nom.trim().isEmpty) {
      return Response.badRequest(
        body: '{"erreur": "Le champ nom est requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final result = db.select(
      'SELECT id FROM types_produits WHERE id = ?;',
      [int.parse(id)],
    );
    if (result.isEmpty) {
      return Response.notFound(
        '{"erreur": "Type introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    db.execute(
      'UPDATE types_produits SET nom = ?, description = ? WHERE id = ?',
      [nom.trim(), data['description'], int.parse(id)],
    );

    final rows = db.select(
      'SELECT * FROM types_produits WHERE id = ?;',
      [int.parse(id)],
    );
    return Response.ok(
      jsonEncode(TypeProduit.fromMap(rows.first).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // ─── DELETE /types/:id ───────────────────────────────────────────────────────
  // Supprime un type (échoue si des produits y sont rattachés)
  router.delete('/<id>', (Request req, String id) {
    if (req.context['role'] != 'admin') return _forbidden();
    final result = db.select(
      'SELECT id FROM types_produits WHERE id = ?;',
      [int.parse(id)],
    );
    if (result.isEmpty) {
      return Response.notFound(
        '{"erreur": "Type introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      db.execute(
        'DELETE FROM types_produits WHERE id = ?',
        [int.parse(id)],
      );
    } catch (e) {
      // SQLite lève une erreur si des produits utilisent ce type (FOREIGN KEY)
      return Response(
        409, // Conflict
        body: '{"erreur": "Impossible de supprimer : des produits utilisent ce type"}',
        headers: {'content-type': 'application/json'},
      );
    }

    return Response(204); // 204 No Content : suppression réussie, pas de corps
  });

  return router;
}
