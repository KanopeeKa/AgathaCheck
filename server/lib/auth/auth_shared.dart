import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

import '../jwt_secret.dart';

const jsonHeaders = {'Content-Type': 'application/json'};

final uuid = Uuid();
final dbcrypt = DBCrypt();

String signAccessToken(String userId, String email) {
  final jwt = JWT({'id': userId, 'email': email});
  return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(minutes: 30));
}

String signRefreshToken(String userId, String email) {
  final jwt = JWT({'id': userId, 'email': email});
  return jwt.sign(SecretKey(jwtSecret), expiresIn: Duration(days: 30));
}

Map<String, dynamic>? verifyToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    return jwt.payload as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String? extractToken(Request request) {
  final auth =
      request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

Map<String, dynamic> userRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'email': c['email'],
    'first_name': c['first_name'] ?? '',
    'last_name': c['last_name'] ?? '',
    'category': c['category'] ?? 'pet_guardian',
    'bio': c['bio'] ?? '',
    'photo_url': c['photo_url'] ?? '',
    'locale': c['locale'] ?? 'en',
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}
