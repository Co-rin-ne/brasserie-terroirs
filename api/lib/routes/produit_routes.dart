import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../models/produit.dart';

// Réponse 403 réutilisable
Response _forbiddenAdmin() => Response.forbidden(
      '{"erreur": "Accès réservé à l\'administrateur"}',
      headers: {'content-type': 'application/json'},
    );

Router produitRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // GET /produits — liste avec jointures pour avoir les noms (pas juste les ids)
  router.get('/', (Request req) async {
    // On joint les 3 tables pour retourner les infos complètes
    final rows = await db.query('''
      SELECT
        p.id, p.nom, p.description, p.quantite_stock, p.prix, p.image_url,
        p.id_type, tp.nom as type_nom,
        p.id_format, f.libelle as format_libelle, f.contenance
      FROM produits p
      JOIN types_produits tp ON tp.id = p.id_type
      JOIN formats f         ON f.id  = p.id_format
      ORDER BY p.nom;
    ''');

    final produits = rows.toMapList().map((r) {
      final map = Produit.fromMap(r).toMap();
      // On enrichit la réponse avec les noms (utile pour l'affichage React)
      map['type_nom'] = r['type_nom'];
      map['format_libelle'] = r['format_libelle'];
      map['contenance'] = toDouble(r['contenance']);
      return map;
    }).toList();

    return Response.ok(
      jsonEncode(produits),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /produits/:id
  router.get('/<id>', (Request req, String id) async {
    final rows = await db.query('''
      SELECT
        p.id, p.nom, p.description, p.quantite_stock, p.prix, p.image_url,
        p.id_type, tp.nom as type_nom,
        p.id_format, f.libelle as format_libelle, f.contenance
      FROM produits p
      JOIN types_produits tp ON tp.id = p.id_type
      JOIN formats f         ON f.id  = p.id_format
      WHERE p.id = ?;
    ''', [int.parse(id)]);

    if (rows.isEmpty) {
      return Response.notFound(
        '{"erreur": "Produit introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final r = rows.firstAsMap!;
    final map = Produit.fromMap(r).toMap();
    map['type_nom'] = r['type_nom'];
    map['format_libelle'] = r['format_libelle'];
    map['contenance'] = toDouble(r['contenance']);

    return Response.ok(
      jsonEncode(map),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /produits — crée un produit
  router.post('/', (Request req) async {
    if (req.context['role'] != 'admin') return _forbiddenAdmin();

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

    // Validation des champs obligatoires
    final nom = data['nom'] as String?;
    final prix = data['prix'];
    final idType = data['id_type'];
    final idFormat = data['id_format'];

    if (nom == null || nom.trim().isEmpty ||
        prix == null || idType == null || idFormat == null) {
      return Response.badRequest(
        body: '{"erreur": "nom, prix, id_type et id_format sont requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final result = await db.query(
      '''INSERT INTO produits (nom, description, quantite_stock, prix, image_url, id_type, id_format)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [
        nom.trim(),
        data['description'],
        data['quantite_stock'] ?? 0,
        (prix as num).toDouble(),
        data['image_url'],
        idType as int,
        idFormat as int,
      ],
    );

    final newId = result.insertId;
    // On réutilise la même requête GET pour avoir les jointures
    final rows = await db.query('''
      SELECT p.id, p.nom, p.description, p.quantite_stock, p.prix, p.image_url,
             p.id_type, p.id_format, tp.nom as type_nom, f.libelle as format_libelle, f.contenance
      FROM produits p
      JOIN types_produits tp ON tp.id = p.id_type
      JOIN formats f         ON f.id  = p.id_format
      WHERE p.id = ?;
    ''', [newId]);

    final r = rows.firstAsMap!;
    final map = Produit.fromMap(r).toMap();
    map['type_nom'] = r['type_nom'];
    map['format_libelle'] = r['format_libelle'];
    map['contenance'] = toDouble(r['contenance']);

    return Response(
      201,
      body: jsonEncode(map),
      headers: {'content-type': 'application/json'},
    );
  });

  // PUT /produits/:id — modifie un produit (admin uniquement)
  router.put('/<id>', (Request req, String id) async {
    if (req.context['role'] != 'admin') return _forbiddenAdmin();
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

    final existing = await db.query(
      'SELECT id FROM produits WHERE id = ?;',
      [int.parse(id)],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Produit introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final nom = data['nom'] as String?;
    final prix = data['prix'];
    final idType = data['id_type'];
    final idFormat = data['id_format'];

    if (nom == null || nom.trim().isEmpty ||
        prix == null || idType == null || idFormat == null) {
      return Response.badRequest(
        body: '{"erreur": "nom, prix, id_type et id_format sont requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    await db.query(
      '''UPDATE produits
         SET nom = ?, description = ?, quantite_stock = ?, prix = ?, image_url = ?, id_type = ?, id_format = ?
         WHERE id = ?''',
      [
        nom.trim(),
        data['description'],
        data['quantite_stock'] ?? 0,
        (prix as num).toDouble(),
        data['image_url'],
        idType as int,
        idFormat as int,
        int.parse(id),
      ],
    );

    final rows = await db.query('''
      SELECT p.id, p.nom, p.description, p.quantite_stock, p.prix, p.image_url,
             p.id_type, p.id_format, tp.nom as type_nom, f.libelle as format_libelle, f.contenance
      FROM produits p
      JOIN types_produits tp ON tp.id = p.id_type
      JOIN formats f         ON f.id  = p.id_format
      WHERE p.id = ?;
    ''', [int.parse(id)]);

    final r = rows.firstAsMap!;
    final map = Produit.fromMap(r).toMap();
    map['type_nom'] = r['type_nom'];
    map['format_libelle'] = r['format_libelle'];
    map['contenance'] = toDouble(r['contenance']);

    return Response.ok(
      jsonEncode(map),
      headers: {'content-type': 'application/json'},
    );
  });

  // DELETE /produits/:id (admin uniquement)
  router.delete('/<id>', (Request req, String id) async {
    if (req.context['role'] != 'admin') return _forbiddenAdmin();
    final existing = await db.query(
      'SELECT id FROM produits WHERE id = ?;',
      [int.parse(id)],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Produit introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    await db.query('DELETE FROM produits WHERE id = ?', [int.parse(id)]);
    return Response(204);
  });

  return router;
}
