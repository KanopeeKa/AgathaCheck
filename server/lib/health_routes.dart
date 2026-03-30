import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:io';

final _uuid = Uuid();
final _jwtSecret = Platform.environment['JWT_SECRET'] ??
    Platform.environment['SESSION_SECRET'] ??
    'default_secret';
const _jsonHeaders = {'Content-Type': 'application/json'};

String? _extractUserId(Request request) {
  final auth =
      request.headers['authorization'] ?? request.headers['Authorization'];
  if (auth == null || !auth.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(auth.substring(7), SecretKey(_jwtSecret));
    return (jwt.payload as Map)['id']?.toString();
  } catch (_) {
    return null;
  }
}

Router healthRoutes(Pool pool) {
  final router = Router();

  router.get('/', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.user_id = @userId ORDER BY he.next_due_date ASC NULLS LAST, he.created_at DESC'),
        parameters: {'userId': userId},
      );
      final entries = results.map((row) => _healthEntryToMap(row)).toList();
      return Response.ok(jsonEncode(entries), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error fetching entries: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/export', (Request request) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.user_id = @userId ORDER BY he.created_at DESC'),
        parameters: {'userId': userId},
      );
      final csv = StringBuffer('id,pet_name,name,type,dosage,frequency,start_date,next_due_date,notes\n');
      for (final row in results) {
        final c = row.toColumnMap();
        csv.writeln('${c['id']},${c['pet_name']},${c['name']},${c['type']},${c['dosage']},${c['frequency']},${c['start_date']},${c['next_due_date']},${c['notes']}');
      }
      return Response.ok(csv.toString(), headers: {'Content-Type': 'text/csv'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Export failed: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT he.*, p.name as pet_name FROM health_entries he JOIN pets p ON he.pet_id = p.id WHERE he.id = @id AND he.user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Entry not found'}), headers: _jsonHeaders);
      }
      return Response.ok(jsonEncode(_healthEntryToMap(results.first)), headers: _jsonHeaders);
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
      final startDateStr = data['start_date'] ?? data['startDate'];
      final nextDueStr = data['next_due_date'] ?? data['nextDueDate'];
      final results = await pool.execute(
        Sql.named('INSERT INTO health_entries (id, pet_id, user_id, name, type, dosage, frequency, frequency_days, frequency_interval, start_date, next_due_date, notes, health_issue_id, remind_days_before, status) VALUES (@id, @pet_id, @user_id, @name, @type, @dosage, @frequency, @frequency_days, @frequency_interval, @start_date, @next_due_date, @notes, @health_issue_id, @remind_days_before, @status) RETURNING *'),
        parameters: {
          'id': id,
          'pet_id': data['pet_id'] ?? data['petId'],
          'user_id': userId,
          'name': data['name'] ?? '',
          'type': data['type'] ?? 'vet_visit',
          'dosage': data['dosage'] ?? '',
          'frequency': data['frequency'] ?? 'once',
          'frequency_days': data['frequency_days'] ?? data['frequencyDays'],
          'frequency_interval': data['frequency_interval'] ?? data['frequencyInterval'] ?? 1,
          'start_date': startDateStr != null ? DateTime.parse(startDateStr.toString()) : null,
          'next_due_date': nextDueStr != null ? DateTime.parse(nextDueStr.toString()) : null,
          'notes': data['notes'] ?? '',
          'health_issue_id': data['health_issue_id'] ?? data['healthIssueId'],
          'remind_days_before': data['remind_days_before'] ?? data['remindDaysBefore'] ?? 1,
          'status': data['status'] ?? 'active',
        },
      );
      return Response(201, body: jsonEncode(_healthEntryToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error creating entry: $e'}), headers: _jsonHeaders);
    }
  });

  router.put('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final startDateStr = data['start_date'] ?? data['startDate'];
      final nextDueStr = data['next_due_date'] ?? data['nextDueDate'];
      final results = await pool.execute(
        Sql.named('UPDATE health_entries SET name = @name, type = @type, dosage = @dosage, frequency = @frequency, frequency_days = @frequency_days, frequency_interval = @frequency_interval, start_date = @start_date, next_due_date = @next_due_date, notes = @notes, health_issue_id = @health_issue_id, remind_days_before = @remind_days_before, status = @status, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {
          'id': id,
          'userId': userId,
          'name': data['name'] ?? '',
          'type': data['type'] ?? 'vet_visit',
          'dosage': data['dosage'] ?? '',
          'frequency': data['frequency'] ?? 'once',
          'frequency_days': data['frequency_days'] ?? data['frequencyDays'],
          'frequency_interval': data['frequency_interval'] ?? data['frequencyInterval'] ?? 1,
          'start_date': startDateStr != null ? DateTime.parse(startDateStr.toString()) : null,
          'next_due_date': nextDueStr != null ? DateTime.parse(nextDueStr.toString()) : null,
          'notes': data['notes'] ?? '',
          'health_issue_id': data['health_issue_id'] ?? data['healthIssueId'],
          'remind_days_before': data['remind_days_before'] ?? data['remindDaysBefore'] ?? 1,
          'status': data['status'] ?? 'active',
        },
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Entry not found'}), headers: _jsonHeaders);
      }
      return Response.ok(jsonEncode(_healthEntryToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error updating entry: $e'}), headers: _jsonHeaders);
    }
  });

  router.delete('/<id>', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM health_entries WHERE id = @id AND user_id = @userId'),
        parameters: {'id': id, 'userId': userId},
      );
      return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/<id>/mark-taken', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('UPDATE health_entries SET status = \'completed\', completed_at = NOW(), updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Entry not found'}), headers: _jsonHeaders);
      }
      await pool.execute(
        Sql.named('INSERT INTO health_history (id, health_entry_id, status, notes) VALUES (@id, @entry_id, \'completed\', \'Marked as taken\')'),
        parameters: {'id': _uuid.v4(), 'entry_id': id},
      );
      return Response.ok(jsonEncode(_healthEntryToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.post('/<id>/undo-complete', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('UPDATE health_entries SET status = \'active\', completed_at = NULL, updated_at = NOW() WHERE id = @id AND user_id = @userId RETURNING *'),
        parameters: {'id': id, 'userId': userId},
      );
      if (results.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Entry not found'}), headers: _jsonHeaders);
      }
      return Response.ok(jsonEncode(_healthEntryToMap(results.first)), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>/history', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT * FROM health_history WHERE health_entry_id = @id ORDER BY changed_at DESC'),
        parameters: {'id': id},
      );
      final history = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'health_entry_id': c['health_entry_id']?.toString(),
          'status': c['status'],
          'notes': c['notes'] ?? '',
          'changed_at': c['changed_at']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(history), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.get('/<id>/photos', (Request request, String id) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      final results = await pool.execute(
        Sql.named('SELECT * FROM health_event_photos WHERE health_entry_id = @id ORDER BY created_at DESC'),
        parameters: {'id': id},
      );
      final photos = results.map((row) {
        final c = row.toColumnMap();
        return {
          'id': c['id']?.toString(),
          'health_entry_id': c['health_entry_id']?.toString(),
          'url': c['url'],
          'created_at': c['created_at']?.toString(),
        };
      }).toList();
      return Response.ok(jsonEncode(photos), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  router.delete('/<entryId>/photos/<photoId>', (Request request, String entryId, String photoId) async {
    final userId = _extractUserId(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}), headers: _jsonHeaders);
    }
    try {
      await pool.execute(
        Sql.named('DELETE FROM health_event_photos WHERE id = @id AND health_entry_id = @entryId'),
        parameters: {'id': photoId, 'entryId': entryId},
      );
      return Response.ok(jsonEncode({'deleted': true}), headers: _jsonHeaders);
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'Error: $e'}), headers: _jsonHeaders);
    }
  });

  return router;
}

Map<String, dynamic> _healthEntryToMap(ResultRow row) {
  final c = row.toColumnMap();
  return {
    'id': c['id']?.toString(),
    'pet_id': c['pet_id']?.toString(),
    'user_id': c['user_id']?.toString(),
    'pet_name': c['pet_name'],
    'name': c['name'] ?? '',
    'type': c['type'],
    'dosage': c['dosage'] ?? '',
    'frequency': c['frequency'] ?? 'once',
    'frequency_days': c['frequency_days'],
    'frequency_interval': c['frequency_interval'] ?? 1,
    'start_date': c['start_date']?.toString(),
    'next_due_date': c['next_due_date']?.toString(),
    'notes': c['notes'] ?? '',
    'health_issue_id': c['health_issue_id']?.toString(),
    'remind_days_before': c['remind_days_before'] ?? 1,
    'status': c['status'] ?? 'active',
    'completed_at': c['completed_at']?.toString(),
    'created_at': c['created_at']?.toString(),
    'updated_at': c['updated_at']?.toString(),
  };
}
