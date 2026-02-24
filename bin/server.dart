import 'dart:convert';
import 'dart:io';

import 'package:postgres/postgres.dart';

late Connection _db;

Future<void> main() async {
  final portStr = Platform.environment['PORT'] ?? '5000';
  final port = int.parse(portStr);

  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null) {
    print('Error: DATABASE_URL not set.');
    exit(1);
  }

  _db = await Connection.open(
    Endpoint(
      host: Platform.environment['PGHOST'] ?? 'localhost',
      port: int.parse(Platform.environment['PGPORT'] ?? '5432'),
      database: Platform.environment['PGDATABASE'] ?? 'postgres',
      username: Platform.environment['PGUSER'] ?? 'postgres',
      password: Platform.environment['PGPASSWORD'] ?? '',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );
  print('Connected to PostgreSQL');

  final server = await HttpServer.bind('0.0.0.0', port);
  server.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');
  server.defaultResponseHeaders.remove('x-xss-protection', '1; mode=block');
  server.defaultResponseHeaders.remove('x-content-type-options', 'nosniff');
  print('Serving on http://0.0.0.0:$port');

  final webDir = Directory('deploy/public');

  await for (final request in server) {
    try {
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods',
          'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers.set(
          'Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        continue;
      }

      final path = request.uri.path;

      if (path.startsWith('/api/')) {
        await _handleApi(request);
      } else {
        await _serveStatic(request, webDir);
      }

    } catch (e, st) {
      print('Error handling ${request.uri}: $e\n$st');
      request.response.statusCode = 500;
      request.response.headers.set('Content-Type', 'application/json');
      request.response.write(json.encode({'error': 'Internal server error'}));
      await request.response.close();
    }
  }
}

Future<void> _handleApi(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  if (path == '/api/health-entries' && method == 'GET') {
    await _getHealthEntries(request);
  } else if (path == '/api/health-entries' && method == 'POST') {
    await _createHealthEntry(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+$').hasMatch(path) &&
      method == 'GET') {
    await _getHealthEntry(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+$').hasMatch(path) &&
      method == 'PUT') {
    await _updateHealthEntry(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+$').hasMatch(path) &&
      method == 'DELETE') {
    await _deleteHealthEntry(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+/mark-taken$')
          .hasMatch(path) &&
      method == 'POST') {
    await _markTaken(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+/history$').hasMatch(path) &&
      method == 'GET') {
    await _getHistory(request);
  } else if (path == '/api/health-entries/export' && method == 'GET') {
    await _exportCsv(request);
  } else {
    _jsonResponse(request, 404, {'error': 'Not found'});
  }
}

Future<void> _getHealthEntries(HttpRequest request) async {
  final petId = request.uri.queryParameters['pet_id'];
  final type = request.uri.queryParameters['type'];

  var query = 'SELECT * FROM health_entries WHERE 1=1';
  final params = <String, dynamic>{};

  if (petId != null && petId.isNotEmpty) {
    query += ' AND pet_id = @petId';
    params['petId'] = petId;
  }
  if (type != null && type.isNotEmpty) {
    query += ' AND type = @type';
    params['type'] = type;
  }

  query += ' ORDER BY next_due_date ASC';

  final result = await _db.execute(Sql.named(query),
      parameters: params.isEmpty ? null : params);
  final entries = result.map(_rowToMap).toList();
  _jsonResponse(request, 200, entries);
}

Future<void> _getHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('SELECT * FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  _jsonResponse(request, 200, _rowToMap(result.first));
}

Future<void> _createHealthEntry(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final name = body['name'] as String? ?? '';
  final type = body['type'] as String? ?? '';
  final dosage = body['dosage'] as String? ?? '';
  final frequency = body['frequency'] as String? ?? '';
  final frequencyDays = body['frequency_days'] as int?;
  final startDate = body['start_date'] as String? ?? '';
  final nextDueDate = body['next_due_date'] as String? ?? startDate;
  final notes = body['notes'] as String? ?? '';
  final petId = body['pet_id'] as String? ?? '';

  if (name.isEmpty || type.isEmpty || frequency.isEmpty || startDate.isEmpty) {
    _jsonResponse(
        request, 400, {'error': 'name, type, frequency, start_date required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO health_entries (pet_id, name, type, dosage, frequency, frequency_days, start_date, next_due_date, notes)
      VALUES (@petId, @name, @type, @dosage, @frequency, @frequencyDays, @startDate::date, @nextDueDate::timestamptz, @notes)
      RETURNING *
    '''),
    parameters: {
      'petId': petId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'frequencyDays': frequencyDays,
      'startDate': startDate,
      'nextDueDate': nextDueDate,
      'notes': notes,
    },
  );

  _jsonResponse(request, 201, _rowToMap(result.first));
}

Future<void> _updateHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _db.execute(
    Sql.named('SELECT * FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  final row = _rowToMap(existing.first);

  final result = await _db.execute(
    Sql.named('''
      UPDATE health_entries SET
        name = @name, type = @type, dosage = @dosage,
        frequency = @frequency, frequency_days = @frequencyDays,
        start_date = @startDate::date, next_due_date = @nextDueDate::timestamptz,
        notes = @notes, updated_at = NOW()
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'id': id,
      'name': body['name'] ?? row['name'],
      'type': body['type'] ?? row['type'],
      'dosage': body['dosage'] ?? row['dosage'],
      'frequency': body['frequency'] ?? row['frequency'],
      'frequencyDays': body['frequency_days'] ?? row['frequency_days'],
      'startDate': body['start_date'] ?? row['start_date'],
      'nextDueDate': body['next_due_date'] ?? row['next_due_date'],
      'notes': body['notes'] ?? row['notes'],
    },
  );

  _jsonResponse(request, 200, _rowToMap(result.first));
}

Future<void> _deleteHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('DELETE FROM health_entries WHERE id = @id RETURNING id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  _jsonResponse(request, 200, {'deleted': true});
}

Future<void> _markTaken(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final id = segments[segments.length - 2];
  final body = await _readJson(request);

  final existing = await _db.execute(
    Sql.named('SELECT * FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  final row = _rowToMap(existing.first);
  final historyNotes = body?['notes'] as String? ?? '';

  await _db.execute(
    Sql.named('''
      INSERT INTO health_history (entry_id, notes)
      VALUES (@entryId, @notes)
    '''),
    parameters: {'entryId': id, 'notes': historyNotes},
  );

  final frequency = row['frequency'] as String;
  final currentDue = DateTime.parse(row['next_due_date'].toString());
  DateTime nextDue;

  switch (frequency) {
    case 'daily':
      nextDue = currentDue.add(const Duration(days: 1));
      break;
    case 'weekly':
      nextDue = currentDue.add(const Duration(days: 7));
      break;
    case 'monthly':
      nextDue = DateTime(currentDue.year, currentDue.month + 1, currentDue.day,
          currentDue.hour, currentDue.minute);
      break;
    case 'custom':
      final days = row['frequency_days'] as int? ?? 1;
      nextDue = currentDue.add(Duration(days: days));
      break;
    default:
      nextDue = currentDue.add(const Duration(days: 1));
  }

  final updated = await _db.execute(
    Sql.named('''
      UPDATE health_entries SET next_due_date = @nextDue, updated_at = NOW()
      WHERE id = @id RETURNING *
    '''),
    parameters: {'id': id, 'nextDue': nextDue.toIso8601String()},
  );

  _jsonResponse(request, 200, _rowToMap(updated.first));
}

Future<void> _getHistory(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final id = segments[segments.length - 2];

  final result = await _db.execute(
    Sql.named('''
      SELECT * FROM health_history WHERE entry_id = @entryId
      ORDER BY taken_at DESC
    '''),
    parameters: {'entryId': id},
  );

  final history = result.map((r) {
    final cols = r.toColumnMap();
    return {
      'id': cols['id'].toString(),
      'entry_id': cols['entry_id'].toString(),
      'taken_at': cols['taken_at'].toString(),
      'notes': cols['notes'].toString(),
    };
  }).toList();

  _jsonResponse(request, 200, history);
}

Future<void> _exportCsv(HttpRequest request) async {
  final petId = request.uri.queryParameters['pet_id'];

  var query = '''
    SELECT he.*, 
      (SELECT COUNT(*) FROM health_history hh WHERE hh.entry_id = he.id) as times_taken,
      (SELECT MAX(hh.taken_at) FROM health_history hh WHERE hh.entry_id = he.id) as last_taken
    FROM health_entries he
  ''';
  final params = <String, dynamic>{};

  if (petId != null && petId.isNotEmpty) {
    query += ' WHERE he.pet_id = @petId';
    params['petId'] = petId;
  }
  query += ' ORDER BY he.name';

  final result = await _db.execute(Sql.named(query),
      parameters: params.isEmpty ? null : params);

  final buffer = StringBuffer();
  buffer.writeln(
      'Name,Type,Dosage,Frequency,Start Date,Next Due Date,Notes,Times Taken,Last Taken');

  for (final row in result) {
    final cols = row.toColumnMap();
    buffer.writeln([
      _csvEscape(cols['name'].toString()),
      _csvEscape(cols['type'].toString()),
      _csvEscape(cols['dosage'].toString()),
      _csvEscape(cols['frequency'].toString()),
      _csvEscape(cols['start_date'].toString()),
      _csvEscape(cols['next_due_date'].toString()),
      _csvEscape(cols['notes'].toString()),
      cols['times_taken'] ?? 0,
      _csvEscape((cols['last_taken'] ?? '').toString()),
    ].join(','));
  }

  request.response.statusCode = 200;
  request.response.headers.set('Content-Type', 'text/csv');
  request.response.headers
      .set('Content-Disposition', 'attachment; filename="health_entries.csv"');
  request.response.write(buffer.toString());
  await request.response.close();
}

String _csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

Map<String, dynamic> _rowToMap(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'pet_id': cols['pet_id'].toString(),
    'name': cols['name'].toString(),
    'type': cols['type'].toString(),
    'dosage': cols['dosage'].toString(),
    'frequency': cols['frequency'].toString(),
    'frequency_days': cols['frequency_days'],
    'start_date': cols['start_date'].toString(),
    'next_due_date': cols['next_due_date'].toString(),
    'notes': cols['notes'].toString(),
    'created_at': cols['created_at'].toString(),
    'updated_at': cols['updated_at'].toString(),
  };
}

void _jsonResponse(
    HttpRequest request, int status, dynamic body) {
  request.response.statusCode = status;
  request.response.headers.set('Content-Type', 'application/json');
  request.response.write(json.encode(body));
  request.response.close();
}

Future<Map<String, dynamic>?> _readJson(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    if (body.isEmpty) return {};
    return json.decode(body) as Map<String, dynamic>;
  } catch (e) {
    _jsonResponse(request, 400, {'error': 'Invalid JSON'});
    return null;
  }
}

Future<void> _serveStatic(HttpRequest request, Directory webDir) async {
  if (!webDir.existsSync()) {
    request.response.statusCode = 404;
    request.response.write('Web directory not found');
    await request.response.close();
    return;
  }

  var path = request.uri.path;
  if (path == '/') path = '/index.html';

  final file = File('${webDir.path}$path');
  if (await file.exists()) {
    final ext = path.split('.').last;
    final contentType = _mimeType(ext);
    request.response.headers.set('Content-Type', contentType);
    request.response.headers.set('Cache-Control', 'no-cache');
    await request.response.addStream(file.openRead());
  } else {
    final indexFile = File('${webDir.path}/index.html');
    if (await indexFile.exists()) {
      request.response.headers.set('Content-Type', 'text/html');
      request.response.headers.set('Cache-Control', 'no-cache');
      await request.response.addStream(indexFile.openRead());
    } else {
      request.response.statusCode = 404;
      request.response.write('Not found');
    }
  }
  await request.response.close();
}

String _mimeType(String ext) {
  switch (ext) {
    case 'html':
      return 'text/html';
    case 'js':
      return 'application/javascript';
    case 'css':
      return 'text/css';
    case 'json':
      return 'application/json';
    case 'png':
      return 'image/png';
    case 'ico':
      return 'image/x-icon';
    case 'woff':
      return 'font/woff';
    case 'woff2':
      return 'font/woff2';
    case 'ttf':
      return 'font/ttf';
    case 'otf':
      return 'font/otf';
    case 'wasm':
      return 'application/wasm';
    default:
      return 'application/octet-stream';
  }
}
