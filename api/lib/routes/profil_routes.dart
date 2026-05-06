import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';

// Routes pour le profil du client connecté

Router profilRouter() {
  final router = Router();
  final db = AppDatabase.instance.db;

  // GET /profil — infos de l'utilisateur connecté
  router.get('/', (Request req) {
    final id = req.context['userId'] as int;
    final rows = db.select(
      'SELECT id, nom, email, role FROM utilisateurs WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) {
      return Response.notFound('{"erreur": "Utilisateur introuvable"}',
          headers: {'content-type': 'application/json'});
    }
    return Response.ok(
      jsonEncode({'id': rows.first['id'], 'nom': rows.first['nom'], 'email': rows.first['email']}),
      headers: {'content-type': 'application/json'},
    );
  });

  // PUT /profil/password — modifier son mot de passe
  router.put('/password', (Request req) async {
    final id = req.context['userId'] as int;
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

    final ancien = data['ancien_mot_de_passe'] as String?;
    final nouveau = data['nouveau_mot_de_passe'] as String?;

    if (ancien == null || nouveau == null || nouveau.length < 6) {
      return Response.badRequest(
        body: '{"erreur": "ancien_mot_de_passe et nouveau_mot_de_passe (6 car. min) requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final hashAncien = AppDatabase.hashPassword(ancien);
    final rows = db.select(
      'SELECT id FROM utilisateurs WHERE id = ? AND mot_de_passe = ?;',
      [id, hashAncien],
    );
    if (rows.isEmpty) {
      return Response.unauthorized(
        '{"erreur": "Mot de passe actuel incorrect"}',
        headers: {'content-type': 'application/json'},
      );
    }

    db.execute(
      'UPDATE utilisateurs SET mot_de_passe = ? WHERE id = ?',
      [AppDatabase.hashPassword(nouveau), id],
    );

    return Response.ok(
      '{"message": "Mot de passe modifié avec succès"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // DELETE /profil — supprimer son propre compte
  router.delete('/', (Request req) {
    final id = req.context['userId'] as int;
    final role = req.context['role'] as String;

    // Empêche l'admin de supprimer son propre compte
    if (role == 'admin') {
      return Response.forbidden(
        '{"erreur": "L\'administrateur ne peut pas supprimer son compte"}',
        headers: {'content-type': 'application/json'},
      );
    }

    db.execute('DELETE FROM utilisateurs WHERE id = ?', [id]);
    return Response(204);
  });

  return router;
}
