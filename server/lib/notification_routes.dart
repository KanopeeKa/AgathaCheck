import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_secret.dart';
import 'http_security.dart';

const _jsonHeaders = {'Content-Type': 'application/json'};

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

Router notificationRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'SELECT * FROM notifications WHERE user_id = @userId ORDER BY created_at DESC'),
        parameters: {'userId': userId},
      );
      final notifications =
          results.map((row) => _notificationToMap(row)).toList();
      return Response.ok(jsonEncode(notifications), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.get('/unread-count', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'SELECT COUNT(*) as count FROM notifications WHERE user_id = @userId AND (is_read = false OR (is_read IS NULL AND read = false))'),
        parameters: {'userId': userId},
      );
      final count = results.first.toColumnMap()['count'] ?? 0;
      return Response.ok(jsonEncode({'unread_count': count}),
          headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.put('/read-all', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named(
            'UPDATE notifications SET is_read = true, read = true WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      return Response.ok(jsonEncode({'success': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.get('/preferences', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named(
            'SELECT * FROM notification_preferences WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      final prefs = <String, dynamic>{};
      for (final row in results) {
        final c = row.toColumnMap();
        prefs[c['preference'] as String] = c['value'];
      }
      return Response.ok(jsonEncode(prefs), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.put('/preferences', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      for (final entry in data.entries) {
        await pool.execute(
          Sql.named(
              'INSERT INTO notification_preferences (id, user_id, preference, value) VALUES (gen_random_uuid(), @userId, @pref, @val) ON CONFLICT (id) DO UPDATE SET value = @val'),
          parameters: {
            'userId': userId,
            'pref': entry.key,
            'val': entry.value.toString()
          },
        );
      }
      return Response.ok(jsonEncode(data), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.post('/check-due', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      return Response.ok(jsonEncode({'checked': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.put('/<id>/read', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401,
          body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named(
            'UPDATE notifications SET is_read = true, read = true WHERE id = @id AND user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      return Response.ok(jsonEncode({'success': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  return router;
}

Map<String, dynamic> _notificationToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'pet_id': c['pet_id']?.toString(),
    'pet_name': c['pet_name'],
    'health_entry_id': c['health_entry_id']?.toString(),
    'organization_id': c['organization_id']?.toString(),
    'title': c['title'] ?? '',
    'message': c['message'] ?? '',
    'type': c['type'] ?? 'general',
    'is_read': c['is_read'] ?? c['read'] ?? false,
    'created_at': c['created_at']?.toString(),
  };
}
