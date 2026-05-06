import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../database/database.dart';
import '../middleware/auth_middleware.dart';

Router authRouter() {
  final router = Router();

  router.post('/login', (Request req) async {
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

    final email = data['email'] as String?;
    final motDePasse = data['mot_de_passe'] as String?;

    if (email == null || motDePasse == null) {
      return Response.badRequest(
        body: '{"erreur": "email et mot_de_passe requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final hash = AppDatabase.hashPassword(motDePasse);
    final db = AppDatabase.instance.db;

    final rows = db.select(
      'SELECT id, nom, role FROM utilisateurs WHERE email = ? AND mot_de_passe = ?',
      [email, hash],
    );

    if (rows.isEmpty) {
      return Response.unauthorized(
        '{"erreur": "Identifiants incorrects"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final user = rows.first;
    final token = genererToken(user['id'] as int, user['role'] as String);

    // On retourne le token ET le rôle pour que le frontend sache quelle interface afficher
    return Response.ok(
      jsonEncode({
        'token': token,
        'role': user['role'],
        'nom': user['nom'],
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /auth/register — inscription publique (crée un compte client)
  router.post('/register', (Request req) async {
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
        body: '{"erreur": "nom, email et mot de passe (6 car. min) requis"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final db = AppDatabase.instance.db;
    final existing = db.select(
      'SELECT id FROM utilisateurs WHERE email = ?;',
      [email.trim()],
    );
    if (existing.isNotEmpty) {
      return Response(409,
        body: '{"erreur": "Cet email est déjà utilisé"}',
        headers: {'content-type': 'application/json'},
      );
    }

    final hash = AppDatabase.hashPassword(motDePasse);
    db.execute(
      "INSERT INTO utilisateurs (nom, email, mot_de_passe, role) VALUES (?, ?, ?, 'client')",
      [nom.trim(), email.trim(), hash],
    );

    return Response(201,
      body: '{"message": "Compte créé avec succès"}',
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
