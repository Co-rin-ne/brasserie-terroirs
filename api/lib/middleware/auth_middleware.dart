import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

const jwtSecret = 'brasserie_ts_secret_2025';

// Génère un token JWT contenant l'id ET le rôle de l'utilisateur
String genererToken(int userId, String role) {
  final jwt = JWT({'userId': userId, 'role': role}, issuer: 'brasserie-ts');
  return jwt.sign(SecretKey(jwtSecret), expiresIn: const Duration(hours: 8));
}

// Middleware général : vérifie que le token est valide
// Ajoute userId et role dans le contexte de la requête
Middleware authMiddleware() {
  return (Handler inner) => (Request req) async {
    final authHeader = req.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return _unauthorized('Token manquant');
    }

    try {
      final jwt = JWT.verify(authHeader.substring(7), SecretKey(jwtSecret));
      final updated = req.change(context: {
        'userId': jwt.payload['userId'],
        'role': jwt.payload['role'],
      });
      return inner(updated);
    } on JWTExpiredException {
      return _unauthorized('Token expiré, veuillez vous reconnecter');
    } on JWTException {
      return _unauthorized('Token invalide');
    }
  };
}

// Middleware supplémentaire : réserve la route aux admins uniquement
// À chaîner APRÈS authMiddleware
Middleware adminOnly() {
  return (Handler inner) => (Request req) async {
    if (req.context['role'] != 'admin') {
      return Response.forbidden(
        '{"erreur": "Accès réservé à l\'administrateur"}',
        headers: {'content-type': 'application/json'},
      );
    }
    return inner(req);
  };
}

Response _unauthorized(String msg) => Response.unauthorized(
      '{"erreur": "$msg"}',
      headers: {'content-type': 'application/json'},
    );
