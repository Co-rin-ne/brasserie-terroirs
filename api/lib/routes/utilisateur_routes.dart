import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

Response _forbidden() => Response.forbidden(
  '{"erreur": "Accès réservé à l\'administrateur"}',
  headers: {'content-type': 'application/json'},
);

Router utilisateurRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // GET /clients — liste tous les clients
  router.get('/', (Request req) async {
    final rows = await db.query(
      "SELECT id, nom, email FROM utilisateurs WHERE role = 'client' ORDER BY nom;",
    );
    final clients = rows.toMapList().map((r) => {
      'id': r['id'],
      'nom': r['nom']?.toString(),
      'email': r['email']?.toString(),
    }).toList();
    return Response.ok(
      jsonEncode(clients),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /clients — crée un client
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
    final email = data['email'] as String?;
    final motDePasse = data['mot_de_passe'] as String?;

    if (nom == null || nom.trim().isEmpty ||
        email == null || email.trim().isEmpty ||
        motDePasse == null || motDePasse.length < 6) {
      return Response.badRequest(
        body: '{"erreur": "nom, email et mot de passe (6 car. min) sont requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final existing = await db.query(
      'SELECT id FROM utilisateurs WHERE email = ?;',
      [email.trim()],
    );
    if (existing.isNotEmpty) {
      return Response(
        409,
        body: '{"erreur": "Cet email est déjà utilisé"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final hash = AppDatabase.hashPassword(motDePasse);
    final result = await db.query(
      "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, 'client')",
      [nom.trim(), email.trim(), hash],
    );

    return Response(
      201,
      body: jsonEncode({
        'id': result.insertId,
        'nom': nom.trim(),
        'email': email.trim(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // DELETE /clients/:id — supprime un client et sa sélection (CASCADE)
  router.delete('/<id>', (Request req, String id) async {
    if (req.context['role'] != 'admin') return _forbidden();
    final existing = await db.query(
      "SELECT id FROM utilisateurs WHERE id = ? AND role = 'client';",
      [int.parse(id)],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Client introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }
    await db.query('DELETE FROM utilisateurs WHERE id = ?', [int.parse(id)]);
    return Response(204);
  });

  return router;
}
