import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_secret.dart';
import 'http_security.dart';
import 'calendar_date.dart';

final _uuid = Uuid();
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

// True when `petId` exists and belongs to `userId`. Stops a caller from
// attaching weight entries to another user's pet (which the victim would then
// see, since reads join on pets.user_id).
Future<bool> _userOwnsPet(Pool pool, String? petId, String userId) async {
  if (petId == null) return false;
  final r = await pool.execute(
    Sql.named('SELECT 1 FROM pets WHERE id = @petId AND user_id = @userId'),
    parameters: {'petId': petId, 'userId': userId},
  );
  return r.isNotEmpty;
}

Router weightRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final petId = request.url.queryParameters['pet_id'] ?? request.url.queryParameters['petId'];
      String query;
      Map<String, dynamic> params;
      if (petId != null) {
        query = 'SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = @userId AND we.pet_id = @petId ORDER BY we.date DESC';
        params = {'userId': userId, 'petId': petId};
      } else {
        query = 'SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = @userId ORDER BY we.date DESC';
        params = {'userId': userId};
      }
      final results = await pool.execute(Sql.named(query), parameters: params);
      final entries = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'pet_id': c['pet_id']?.toString(),
          'pet_name': c['pet_name'],
          'weight': c['weight'],
          'unit': c['unit'] ?? 'kg',
          'date': dateToIsoDate(c['date']),
          'notes': c['notes'] ?? '',
          'created_at': c['created_at']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(entries), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.get('/latest', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final petId = request.url.queryParameters['pet_id'] ?? request.url.queryParameters['petId'];
      if (petId == null) {
        return Response(400, body: jsonEncode({'error': 'pet_id is required'}), headers: _jsonHeaders);
      }
      final results = await pool.execute(
        Sql.named('SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = @userId AND we.pet_id = @petId ORDER BY we.date DESC LIMIT 1'),
        parameters: {'userId': userId, 'petId': petId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'No weight entries found'}), headers: _jsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(jsonEncode({
        'id': c['id']?.toString(),
        'pet_id': c['pet_id']?.toString(),
        'pet_name': c['pet_name'],
        'weight': c['weight'],
        'unit': c['unit'] ?? 'kg',
        'date': dateToIsoDate(c['date']),
        'notes': c['notes'] ?? '',
        'created_at': c['created_at']?.toString(),
      }), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.post('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final id = data['id'] ?? _uuid.v4();
      final petId = data['pet_id'] ?? data['petId'];
      if (!await _userOwnsPet(pool, petId?.toString(), userId)) {
        return Response(403, body: jsonEncode({'error': 'Forbidden'}), headers: _jsonHeaders);
      }
      final dateStr = data['date'];
      final results = await pool.execute(
        Sql.named('INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes) VALUES (@id, @pet_id, @user_id, @weight, @unit, @date, @notes) RETURNING *'),
        parameters: {
          'id': id,
          'pet_id': petId,
          'user_id': userId,
          'weight': data['weight'] is num ? data['weight'] : double.tryParse(data['weight']?.toString() ?? '0'),
          'unit': data['unit'] ?? 'kg',
          'date': dateToIsoDate(dateStr) ?? todayCalendarIso(),
          'notes': data['notes'] ?? '',
        },
      );
      final c = results.first.toColumnMap();
      return Response(201, body: jsonEncode({
        'id': c['id']?.toString(),
        'pet_id': c['pet_id']?.toString(),
        'weight': c['weight'],
        'unit': c['unit'] ?? 'kg',
        'date': dateToIsoDate(c['date']),
        'notes': c['notes'] ?? '',
        'created_at': c['created_at']?.toString(),
      }), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final dateStr = data['date'];
      final results = await pool.execute(
        Sql.named('UPDATE weight_entries SET weight = @weight, unit = @unit, date = @date, notes = @notes WHERE id = @id AND user_id = @user_id RETURNING *'),
        parameters: {
          'id': id,
          'user_id': userId,
          'weight': data['weight'] is num ? data['weight'] : double.tryParse(data['weight']?.toString() ?? '0'),
          'unit': data['unit'] ?? 'kg',
          'date': dateToIsoDate(dateStr) ?? todayCalendarIso(),
          'notes': data['notes'] ?? '',
        },
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Not found'}), headers: _jsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(jsonEncode({
        'id': c['id']?.toString(),
        'pet_id': c['pet_id']?.toString(),
        'weight': c['weight'],
        'unit': c['unit'] ?? 'kg',
        'date': dateToIsoDate(c['date']),
        'notes': c['notes'] ?? '',
        'created_at': c['created_at']?.toString(),
      }), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM weight_entries WHERE id = @id AND user_id = @user_id'),
        parameters: {'id': id, 'user_id': userId},
      );
      return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': publicError(e)}), headers: _jsonHeaders);
    }
  });

  return router;
}
