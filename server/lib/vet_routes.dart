import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_secret.dart';
import 'http_security.dart';

final _uuid = Uuid();

const _json = {'Content-Type': 'application/json'};

String? _extractUserId(Request request) {
  final auth =
      request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(jwtSecret));
    return (jwt.payload as Map)['id']?.toString();
  } catch (_) {
    return null;
  }
}

Map<String, dynamic> _vetRowToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'name': c['name'],
    'clinic': c['clinic'],
    'phone': c['phone'],
    'email': c['email'],
    'website': c['website'] ?? '',
    'address': c['address'] ?? '',
    'notes': c['notes'] ?? '',
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Router vetRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _json);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'SELECT * FROM vets WHERE user_id = @userId ORDER BY name'),
        parameters: {'userId': userId},
      );
      final list = results
          .map((r) => _vetRowToMap(r))
          .toList();
      return Response.ok(jsonEncode(list), headers: _json);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.get('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _json);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'SELECT * FROM vets WHERE id = @id AND user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Vet not found'}));
      }
      return Response.ok(jsonEncode(_vetRowToMap(results.first)), headers: _json);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.post('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _json);
    }
    try {
      final body = jsonDecode(await request.readAsString());
      final id = _uuid.v4();
      final results = await pool.execute(
        Sql.named(
            'INSERT INTO vets (id, user_id, name, clinic, phone, email, website, address, notes) VALUES (@id, @userId, @name, @clinic, @phone, @email, @website, @address, @notes) RETURNING *'),
        parameters: {
          'id': id,
          'userId': userId,
          'name': body['name'] ?? '',
          'clinic': body['clinic'],
          'phone': body['phone'],
          'email': body['email'],
          'website': body['website'] ?? '',
          'address': body['address'] ?? '',
          'notes': body['notes'] ?? '',
        },
      );
      return Response(201, body: jsonEncode(_vetRowToMap(results.first)), headers: _json);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _json);
    }
    try {
      final body = jsonDecode(await request.readAsString());
      final results = await pool.execute(
        Sql.named(
            'UPDATE vets SET name = @name, clinic = @clinic, phone = @phone, email = @email, website = @website, address = @address, notes = @notes, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {
          'name': body['name'],
          'clinic': body['clinic'],
          'phone': body['phone'],
          'email': body['email'],
          'website': body['website'] ?? '',
          'address': body['address'] ?? '',
          'notes': body['notes'] ?? '',
          'id': id,
          'userId': userId,
        },
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Vet not found'}));
      }
      return Response.ok(jsonEncode(_vetRowToMap(results.first)), headers: _json);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}));
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _json);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'DELETE FROM vets WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Vet not found'}));
      }
      return Response.ok(
          jsonEncode({'message': 'Vet deleted'}), headers: _json);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}));
    }
  });

  return router;
}
