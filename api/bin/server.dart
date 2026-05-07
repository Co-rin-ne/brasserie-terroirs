import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import '../lib/database/database.dart';
import '../lib/middleware/auth_middleware.dart';
import '../lib/routes/auth_routes.dart';
import '../lib/routes/type_produit_routes.dart';
import '../lib/routes/format_routes.dart';
import '../lib/routes/produit_routes.dart';
import '../lib/routes/utilisateur_routes.dart';
import '../lib/routes/selection_routes.dart';
import '../lib/routes/profil_routes.dart';

void main() async {
  // Initialisation asynchrone (connexion à MariaDB + création des tables)
  await AppDatabase.instance.init();
  print('✓ Base de données MariaDB connectée');

  final router = Router();

  router.get('/health', (Request req) =>
      Response.ok('{"status": "ok"}', headers: {'content-type': 'application/json'}));

  // Public
  router.mount('/auth', authRouter().call);

  // Toutes les routes protégées dans un seul handler authentifié.
  // Les vérifications admin (POST/PUT/DELETE) sont faites dans chaque fichier de routes.
  final authHandler = Pipeline()
      .addMiddleware(authMiddleware())
      .addHandler(Router()
        ..mount('/types',        typeProduitRouter().call)
        ..mount('/formats',      formatRouter().call)
        ..mount('/produits',     produitRouter().call)
        ..mount('/clients',      utilisateurRouter().call)
        ..mount('/selection',    selectionRouter().call)
        ..mount('/profil',       profilRouter().call));

  router.mount('/', authHandler);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: {
        ACCESS_CONTROL_ALLOW_ORIGIN: '*',
        ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, OPTIONS',
        ACCESS_CONTROL_ALLOW_HEADERS: 'Content-Type, Authorization',
      }))
      .addHandler(router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('✓ Serveur sur http://localhost:${server.port}\n');
  print('── Public ──────────────────────────────');
  print('  POST /auth/login');
  print('  POST /auth/register');
  print('── Admin (JWT + role=admin) ────────────');
  print('  CRUD /types, /formats, /produits, /clients');
  print('── Client (JWT) ────────────────────────');
  print('  GET/POST/PUT/DELETE /selection');
  print('  POST /selection/valider');
  print('  GET/PUT/DELETE /profil');
}
