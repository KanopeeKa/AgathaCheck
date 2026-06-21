import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'jwt_secret.dart';

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

Map<String, dynamic> _issueRowToMap(Map<String, dynamic> c) {
  return {
    'id': c['id']?.toString(),
    'pet_id': c['pet_id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'pet_name': c['pet_name'],
    'title': c['name'] ?? '',
    'description': c['notes'] ?? '',
    'name': c['name'] ?? '',
    'issue_type': c['issue_type'],
    'notes': c['notes'] ?? '',
    'start_date': c['start_date']?.toString(),
    'end_date': c['end_date']?.toString(),
    'status': c['status'] ?? 'active',
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}

Router healthIssueRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final petId = request.requestedUri.queryParameters['pet_id'] ??
          request.requestedUri.queryParameters['petId'];
      late final Result results;
      if (petId != null && petId.isNotEmpty) {
        results = await pool.execute(
          Sql.named('SELECT hi.*, p.name as pet_name FROM health_issues hi JOIN pets p ON hi.pet_id = p.id WHERE hi.user_id = @userId AND hi.pet_id = @petId ORDER BY hi.created_at DESC'),
          parameters: {'userId': userId, 'petId': petId},
        );
      } else {
        results = await pool.execute(
          Sql.named('SELECT hi.*, p.name as pet_name FROM health_issues hi JOIN pets p ON hi.pet_id = p.id WHERE hi.user_id = @userId ORDER BY hi.created_at DESC'),
          parameters: {'userId': userId},
        );
      }
      final issues = results.map((row) => _issueRowToMap(row.toColumnMap())).toList();
      return Response.ok(jsonEncode(issues), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT * FROM health_issues WHERE id = @id AND user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Not found'}), headers: _jsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(jsonEncode(_issueRowToMap(c)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
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
      final startStr = data['start_date'] ?? data['startDate'];
      final endStr = data['end_date'] ?? data['endDate'];
      final nameVal = data['title'] ?? data['name'] ?? '';
      final notesVal = data['description'] ?? data['notes'] ?? '';
      final results = await pool.execute(
        Sql.named('INSERT INTO health_issues (id, pet_id, user_id, name, issue_type, notes, start_date, end_date, status) VALUES (@id, @pet_id, @user_id, @name, @issue_type, @notes, @start_date, @end_date, @status) RETURNING *'),
        parameters: {
          'id': id,
          'pet_id': data['pet_id'] ?? data['petId'],
          'user_id': userId,
          'name': nameVal,
          'issue_type': data['issue_type'] ?? data['issueType'] ?? 'other',
          'notes': notesVal,
          'start_date': startStr != null ? DateTime.parse(startStr.toString()) : null,
          'end_date': endStr != null ? DateTime.parse(endStr.toString()) : null,
          'status': data['status'] ?? 'active',
        },
      );
      final c = results.first.toColumnMap();
      return Response(201, body: jsonEncode(_issueRowToMap(c)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final startStr = data['start_date'] ?? data['startDate'];
      final endStr = data['end_date'] ?? data['endDate'];
      final nameVal = data['title'] ?? data['name'] ?? '';
      final notesVal = data['description'] ?? data['notes'] ?? '';
      final results = await pool.execute(
        Sql.named('UPDATE health_issues SET name = @name, issue_type = @issue_type, notes = @notes, start_date = @start_date, end_date = @end_date, status = @status, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {
          'id': id,
          'userId': userId,
          'name': nameVal,
          'issue_type': data['issue_type'] ?? data['issueType'] ?? 'other',
          'notes': notesVal,
          'start_date': startStr != null ? DateTime.parse(startStr.toString()) : null,
          'end_date': endStr != null ? DateTime.parse(endStr.toString()) : null,
          'status': data['status'] ?? 'active',
        },
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Not found'}), headers: _jsonHeaders);
      }
      final c = results.first.toColumnMap();
      return Response.ok(jsonEncode(_issueRowToMap(c)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM health_issues WHERE id = @id AND user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  return router;
}
