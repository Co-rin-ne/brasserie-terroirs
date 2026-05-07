import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../models/format.dart';

Response _forbidden() => Response.forbidden(
  '{"erreur": "Accès réservé à l\'administrateur"}',
  headers: {'content-type': 'application/json'},
);

Router formatRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // GET /formats — liste tous les formats
  router.get('/', (Request req) async {
    final rows = await db.query('SELECT * FROM formats ORDER BY libelle;');
    final formats = rows.toMapList()
        .map((r) => Format.fromMap(r).toMap())
        .toList();
    return Response.ok(
      jsonEncode(formats),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /formats/:id
  router.get('/<id>', (Request req, String id) async {
    final rows = await db.query(
      'SELECT * FROM formats WHERE id = ?;',
      [int.parse(id)],
    );
    if (rows.isEmpty) {
      return Response.notFound(
        '{"erreur": "Format introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode(Format.fromMap(rows.firstAsMap!).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /formats — crée un format
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

    final libelle = data['libelle'] as String?;
    final contenance = data['contenance'];
    if (libelle == null || libelle.trim().isEmpty || contenance == null) {
      return Response.badRequest(
        body: '{"erreur": "libelle et contenance sont requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final result = await db.query(
      'INSERT INTO formats (libelle, contenance) VALUES (?, ?)',
      [libelle.trim(), (contenance as num).toDouble()],
    );

    final rows = await db.query(
      'SELECT * FROM formats WHERE id = ?;',
      [result.insertId],
    );
    return Response(
      201,
      body: jsonEncode(Format.fromMap(rows.firstAsMap!).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // PUT /formats/:id — modifie un format
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

    final libelle = data['libelle'] as String?;
    final contenance = data['contenance'];
    if (libelle == null || libelle.trim().isEmpty || contenance == null) {
      return Response.badRequest(
        body: '{"erreur": "libelle et contenance sont requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final existing = await db.query(
      'SELECT id FROM formats WHERE id = ?;',
      [int.parse(id)],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Format introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    await db.query(
      'UPDATE formats SET libelle = ?, contenance = ? WHERE id = ?',
      [libelle.trim(), (contenance as num).toDouble(), int.parse(id)],
    );

    final rows = await db.query(
      'SELECT * FROM formats WHERE id = ?;',
      [int.parse(id)],
    );
    return Response.ok(
      jsonEncode(Format.fromMap(rows.firstAsMap!).toMap()),
      headers: {'content-type': 'application/json'},
    );
  });

  // DELETE /formats/:id
  router.delete('/<id>', (Request req, String id) async {
    if (req.context['role'] != 'admin') return _forbidden();
    final existing = await db.query(
      'SELECT id FROM formats WHERE id = ?;',
      [int.parse(id)],
    );
    if (existing.isEmpty) {
      return Response.notFound(
        '{"erreur": "Format introuvable"}',
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      await db.query('DELETE FROM formats WHERE id = ?', [int.parse(id)]);
    } catch (e) {
      return Response(
        409,
        body: '{"erreur": "Impossible de supprimer : des produits utilisent ce format"}',
        headers: {'content-type': 'application/json'},
      );
    }

    return Response(204);
  });

  return router;
}
