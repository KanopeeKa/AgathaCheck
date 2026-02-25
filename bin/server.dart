// Agatha Pet Profile App — Dart API Server
// Serves REST API endpoints and pre-built Flutter web files.
//
// Auth endpoints:
//   POST /api/auth/signup   — Create account (email, password, name)
//   POST /api/auth/login    — Login (email, password) → tokens
//   POST /api/auth/refresh  — Refresh access token
//   POST /api/auth/logout   — Invalidate refresh token
//   GET  /api/auth/me       — Get current user
//   PUT  /api/auth/me       — Update user profile (name)
//   POST /api/auth/change-password — Change password
//
// Environment variables:
//   DATABASE_URL, PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD
//   SESSION_SECRET — Used as JWT signing key

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:postgres/postgres.dart';

late Connection _db;
late String _jwtSecret;
const _accessTokenExpiry = Duration(minutes: 30);
const _refreshTokenExpiry = Duration(days: 30);

Future<void> main() async {
  final portStr = Platform.environment['PORT'] ?? '5000';
  final port = int.parse(portStr);

  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null) {
    print('Error: DATABASE_URL not set.');
    exit(1);
  }

  _jwtSecret = Platform.environment['SESSION_SECRET'] ?? 'dev-secret-change-me';

  final endpoint = Endpoint(
    host: Platform.environment['PGHOST'] ?? 'localhost',
    port: int.parse(Platform.environment['PGPORT'] ?? '5432'),
    database: Platform.environment['PGDATABASE'] ?? 'postgres',
    username: Platform.environment['PGUSER'] ?? 'postgres',
    password: Platform.environment['PGPASSWORD'] ?? '',
  );

  try {
    _db = await Connection.open(
      endpoint,
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  } catch (_) {
    _db = await Connection.open(
      endpoint,
      settings: ConnectionSettings(sslMode: SslMode.require),
    );
  }
  print('Connected to PostgreSQL');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS shared_pets (
      id SERIAL PRIMARY KEY,
      share_code VARCHAR(12) UNIQUE NOT NULL,
      pet_data JSONB NOT NULL,
      pet_id VARCHAR(255) NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('shared_pets table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('users table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS refresh_tokens (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token VARCHAR(255) UNIQUE NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('refresh_tokens table ready');

  final server = await HttpServer.bind('0.0.0.0', port);
  server.defaultResponseHeaders.remove('x-frame-options', 'SAMEORIGIN');
  server.defaultResponseHeaders.remove('x-xss-protection', '1; mode=block');
  server.defaultResponseHeaders.remove('x-content-type-options', 'nosniff');
  print('Serving on http://0.0.0.0:$port');

  print('\n--- Auth API Ready ---');
  print('POST /api/auth/signup   — Create account');
  print('POST /api/auth/login    — Login');
  print('POST /api/auth/refresh  — Refresh token');
  print('POST /api/auth/logout   — Logout');
  print('GET  /api/auth/me       — Get current user');
  print('PUT  /api/auth/me       — Update profile');
  print('POST /api/auth/change-password — Change password');
  print('');
  print('Example signup:');
  print('  curl -X POST http://localhost:$port/api/auth/signup \\');
  print('    -H "Content-Type: application/json" \\');
  print('    -d \'{"email":"user@example.com","password":"secret123","name":"Jane"}\'');
  print('');
  print('Example login:');
  print('  curl -X POST http://localhost:$port/api/auth/login \\');
  print('    -H "Content-Type: application/json" \\');
  print('    -d \'{"email":"user@example.com","password":"secret123"}\'');
  print('');
  print('Example protected call (use accessToken from login response):');
  print('  curl http://localhost:$port/api/auth/me \\');
  print('    -H "Authorization: Bearer <accessToken>"');
  print('----------------------\n');

  final webDir = Directory('deploy/public');

  await for (final request in server) {
    try {
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods',
          'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers.set(
          'Access-Control-Allow-Headers', 'Content-Type, Authorization');

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

// ── JWT helpers ──────────────────────────────────────────────

String _createAccessToken(int userId, String email) {
  final jwt = JWT({
    'sub': userId.toString(),
    'email': email,
    'type': 'access',
  });
  return jwt.sign(SecretKey(_jwtSecret), expiresIn: _accessTokenExpiry);
}

String _createRefreshTokenValue() {
  final rng = Random.secure();
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return base64Url.encode(bytes);
}

Map<String, dynamic>? _verifyAccessToken(String token) {
  try {
    final jwt = JWT.verify(token, SecretKey(_jwtSecret));
    final payload = jwt.payload as Map<String, dynamic>;
    if (payload['type'] != 'access') return null;
    return payload;
  } catch (_) {
    return null;
  }
}

Future<Map<String, dynamic>?> _authenticateRequest(HttpRequest request) async {
  final authHeader = request.headers.value('authorization');
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring(7);
  return _verifyAccessToken(token);
}

// ── Password helpers ─────────────────────────────────────────

String _hashPassword(String password) {
  return DBCrypt().hashpw(password, DBCrypt().gensalt());
}

bool _checkPassword(String password, String hash) {
  return DBCrypt().checkpw(password, hash);
}

// ── API routing ──────────────────────────────────────────────

Future<void> _handleApi(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  // Auth endpoints
  if (path == '/api/auth/signup' && method == 'POST') {
    await _authSignup(request);
  } else if (path == '/api/auth/login' && method == 'POST') {
    await _authLogin(request);
  } else if (path == '/api/auth/refresh' && method == 'POST') {
    await _authRefresh(request);
  } else if (path == '/api/auth/logout' && method == 'POST') {
    await _authLogout(request);
  } else if (path == '/api/auth/me' && method == 'GET') {
    await _authMe(request);
  } else if (path == '/api/auth/me' && method == 'PUT') {
    await _authUpdateMe(request);
  } else if (path == '/api/auth/change-password' && method == 'POST') {
    await _authChangePassword(request);
  }
  // Health entries
  else if (path == '/api/health-entries' && method == 'GET') {
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
  }
  // Vets
  else if (path == '/api/vets' && method == 'GET') {
    await _getVets(request);
  } else if (path == '/api/vets' && method == 'POST') {
    await _createVet(request);
  } else if (RegExp(r'^/api/vets/[^/]+$').hasMatch(path) && method == 'GET') {
    await _getVet(request);
  } else if (RegExp(r'^/api/vets/[^/]+$').hasMatch(path) && method == 'PUT') {
    await _updateVet(request);
  } else if (RegExp(r'^/api/vets/[^/]+$').hasMatch(path) &&
      method == 'DELETE') {
    await _deleteVet(request);
  }
  // Sharing
  else if (path == '/api/share' && method == 'POST') {
    await _createShare(request);
  } else if (RegExp(r'^/api/share/[^/]+$').hasMatch(path) && method == 'GET') {
    await _getShare(request);
  } else {
    _jsonResponse(request, 404, {'error': 'Not found'});
  }
}

// ── Auth handlers ────────────────────────────────────────────

Future<void> _authSignup(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final password = body['password'] as String? ?? '';
  final name = (body['name'] as String? ?? '').trim();

  if (email.isEmpty || password.isEmpty) {
    _jsonResponse(request, 400, {'error': 'email and password are required'});
    return;
  }

  if (password.length < 6) {
    _jsonResponse(request, 400, {'error': 'Password must be at least 6 characters'});
    return;
  }

  final existing = await _db.execute(
    Sql.named('SELECT id FROM users WHERE email = @email'),
    parameters: {'email': email},
  );
  if (existing.isNotEmpty) {
    _jsonResponse(request, 409, {'error': 'An account with this email already exists'});
    return;
  }

  final hash = _hashPassword(password);
  final result = await _db.execute(
    Sql.named('''
      INSERT INTO users (email, password_hash, name)
      VALUES (@email, @hash, @name)
      RETURNING id, email, name, created_at, updated_at
    '''),
    parameters: {'email': email, 'hash': hash, 'name': name},
  );

  final userRow = result.first.toColumnMap();
  final userId = userRow['id'] as int;
  final accessToken = _createAccessToken(userId, email);
  final refreshToken = _createRefreshTokenValue();

  await _db.execute(
    Sql.named('''
      INSERT INTO refresh_tokens (user_id, token, expires_at)
      VALUES (@userId, @token, @expiresAt)
    '''),
    parameters: {
      'userId': userId,
      'token': refreshToken,
      'expiresAt': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    },
  );

  _jsonResponse(request, 201, {
    'user': {
      'id': userId.toString(),
      'email': userRow['email'].toString(),
      'name': userRow['name'].toString(),
      'created_at': userRow['created_at'].toString(),
      'updated_at': userRow['updated_at'].toString(),
    },
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  });
}

Future<void> _authLogin(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final password = body['password'] as String? ?? '';

  if (email.isEmpty || password.isEmpty) {
    _jsonResponse(request, 400, {'error': 'email and password are required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('SELECT * FROM users WHERE email = @email'),
    parameters: {'email': email},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 401, {'error': 'Invalid email or password'});
    return;
  }

  final userRow = result.first.toColumnMap();
  final hash = userRow['password_hash'].toString();

  if (!_checkPassword(password, hash)) {
    _jsonResponse(request, 401, {'error': 'Invalid email or password'});
    return;
  }

  final userId = userRow['id'] as int;
  final accessToken = _createAccessToken(userId, email);
  final refreshToken = _createRefreshTokenValue();

  await _db.execute(
    Sql.named('''
      INSERT INTO refresh_tokens (user_id, token, expires_at)
      VALUES (@userId, @token, @expiresAt)
    '''),
    parameters: {
      'userId': userId,
      'token': refreshToken,
      'expiresAt': DateTime.now().add(_refreshTokenExpiry).toIso8601String(),
    },
  );

  _jsonResponse(request, 200, {
    'user': {
      'id': userId.toString(),
      'email': userRow['email'].toString(),
      'name': userRow['name'].toString(),
      'created_at': userRow['created_at'].toString(),
      'updated_at': userRow['updated_at'].toString(),
    },
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  });
}

Future<void> _authRefresh(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final refreshToken = body['refreshToken'] as String? ?? '';
  if (refreshToken.isEmpty) {
    _jsonResponse(request, 400, {'error': 'refreshToken is required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      SELECT rt.*, u.email, u.name FROM refresh_tokens rt
      JOIN users u ON u.id = rt.user_id
      WHERE rt.token = @token AND rt.expires_at > NOW()
    '''),
    parameters: {'token': refreshToken},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 401, {'error': 'Invalid or expired refresh token'});
    return;
  }

  final row = result.first.toColumnMap();
  final userId = row['user_id'] as int;
  final email = row['email'].toString();

  final newAccessToken = _createAccessToken(userId, email);

  _jsonResponse(request, 200, {
    'accessToken': newAccessToken,
  });
}

Future<void> _authLogout(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final refreshToken = body['refreshToken'] as String? ?? '';
  if (refreshToken.isNotEmpty) {
    await _db.execute(
      Sql.named('DELETE FROM refresh_tokens WHERE token = @token'),
      parameters: {'token': refreshToken},
    );
  }

  _jsonResponse(request, 200, {'message': 'Logged out'});
}

Future<void> _authMe(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = payload['sub'].toString();
  final result = await _db.execute(
    Sql.named('SELECT id, email, name, created_at, updated_at FROM users WHERE id = @id'),
    parameters: {'id': int.parse(userId)},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  final row = result.first.toColumnMap();
  _jsonResponse(request, 200, {
    'id': row['id'].toString(),
    'email': row['email'].toString(),
    'name': row['name'].toString(),
    'created_at': row['created_at'].toString(),
    'updated_at': row['updated_at'].toString(),
  });
}

Future<void> _authUpdateMe(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final userId = int.parse(payload['sub'].toString());
  final name = body['name'] as String?;

  if (name == null) {
    _jsonResponse(request, 400, {'error': 'name is required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      UPDATE users SET name = @name, updated_at = NOW()
      WHERE id = @id
      RETURNING id, email, name, created_at, updated_at
    '''),
    parameters: {'id': userId, 'name': name.trim()},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  final row = result.first.toColumnMap();
  _jsonResponse(request, 200, {
    'id': row['id'].toString(),
    'email': row['email'].toString(),
    'name': row['name'].toString(),
    'created_at': row['created_at'].toString(),
    'updated_at': row['updated_at'].toString(),
  });
}

Future<void> _authChangePassword(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final currentPassword = body['currentPassword'] as String? ?? '';
  final newPassword = body['newPassword'] as String? ?? '';

  if (currentPassword.isEmpty || newPassword.isEmpty) {
    _jsonResponse(request, 400, {'error': 'currentPassword and newPassword are required'});
    return;
  }

  if (newPassword.length < 6) {
    _jsonResponse(request, 400, {'error': 'New password must be at least 6 characters'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  final userResult = await _db.execute(
    Sql.named('SELECT password_hash FROM users WHERE id = @id'),
    parameters: {'id': userId},
  );

  if (userResult.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  final currentHash = userResult.first.toColumnMap()['password_hash'].toString();
  if (!_checkPassword(currentPassword, currentHash)) {
    _jsonResponse(request, 401, {'error': 'Current password is incorrect'});
    return;
  }

  final newHash = _hashPassword(newPassword);
  await _db.execute(
    Sql.named('UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
    parameters: {'id': userId, 'hash': newHash},
  );

  await _db.execute(
    Sql.named('DELETE FROM refresh_tokens WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  _jsonResponse(request, 200, {'message': 'Password changed successfully. Please log in again.'});
}

// ── Health entries ───────────────────────────────────────────

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

// ── Vets ─────────────────────────────────────────────────────

Future<void> _getVets(HttpRequest request) async {
  final result = await _db.execute(
    Sql.named('SELECT * FROM vets ORDER BY name ASC'),
  );
  final vets = result.map(_vetRowToMap).toList();
  _jsonResponse(request, 200, vets);
}

Future<void> _getVet(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('SELECT * FROM vets WHERE id = @id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Vet not found'});
    return;
  }

  _jsonResponse(request, 200, _vetRowToMap(result.first));
}

Future<void> _createVet(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final name = body['name'] as String? ?? '';
  if (name.isEmpty) {
    _jsonResponse(request, 400, {'error': 'name is required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO vets (name, phone, email, website, address, notes)
      VALUES (@name, @phone, @email, @website, @address, @notes)
      RETURNING *
    '''),
    parameters: {
      'name': name,
      'phone': body['phone'] as String? ?? '',
      'email': body['email'] as String? ?? '',
      'website': body['website'] as String? ?? '',
      'address': body['address'] as String? ?? '',
      'notes': body['notes'] as String? ?? '',
    },
  );

  _jsonResponse(request, 201, _vetRowToMap(result.first));
}

Future<void> _updateVet(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _db.execute(
    Sql.named('SELECT * FROM vets WHERE id = @id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Vet not found'});
    return;
  }

  final row = _vetRowToMap(existing.first);

  final result = await _db.execute(
    Sql.named('''
      UPDATE vets SET
        name = @name, phone = @phone, email = @email,
        website = @website, address = @address, notes = @notes,
        updated_at = NOW()
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'id': int.tryParse(id) ?? 0,
      'name': body['name'] ?? row['name'],
      'phone': body['phone'] ?? row['phone'],
      'email': body['email'] ?? row['email'],
      'website': body['website'] ?? row['website'],
      'address': body['address'] ?? row['address'],
      'notes': body['notes'] ?? row['notes'],
    },
  );

  _jsonResponse(request, 200, _vetRowToMap(result.first));
}

Future<void> _deleteVet(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('DELETE FROM vets WHERE id = @id RETURNING id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Vet not found'});
    return;
  }

  _jsonResponse(request, 200, {'deleted': true});
}

// ── Sharing ──────────────────────────────────────────────────

String _generateShareCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  final rng = Random.secure();
  return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
}

Future<void> _createShare(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final petData = body['pet'] as Map<String, dynamic>?;
  final petId = body['pet_id'] as String? ?? '';

  if (petData == null || petId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'pet and pet_id required'});
    return;
  }

  final existing = await _db.execute(
    Sql.named('SELECT share_code FROM shared_pets WHERE pet_id = @petId'),
    parameters: {'petId': petId},
  );

  if (existing.isNotEmpty) {
    final code = existing.first.toColumnMap()['share_code'].toString();
    await _db.execute(
      Sql.named('''
        UPDATE shared_pets SET pet_data = @petData::jsonb, updated_at = NOW()
        WHERE pet_id = @petId
      '''),
      parameters: {
        'petId': petId,
        'petData': json.encode(petData),
      },
    );
    _jsonResponse(request, 200, {'share_code': code});
    return;
  }

  final code = _generateShareCode();
  await _db.execute(
    Sql.named('''
      INSERT INTO shared_pets (share_code, pet_data, pet_id)
      VALUES (@code, @petData::jsonb, @petId)
    '''),
    parameters: {
      'code': code,
      'petData': json.encode(petData),
      'petId': petId,
    },
  );

  _jsonResponse(request, 201, {'share_code': code});
}

Future<void> _getShare(HttpRequest request) async {
  final code = request.uri.pathSegments.last;

  final result = await _db.execute(
    Sql.named('SELECT * FROM shared_pets WHERE share_code = @code'),
    parameters: {'code': code},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Share not found'});
    return;
  }

  final cols = result.first.toColumnMap();
  final petData = cols['pet_data'];
  final petId = cols['pet_id'].toString();

  final healthResult = await _db.execute(
    Sql.named(
        'SELECT * FROM health_entries WHERE pet_id = @petId ORDER BY next_due_date ASC'),
    parameters: {'petId': petId},
  );
  final healthEntries = healthResult.map(_rowToMap).toList();

  final vetId = (petData is Map) ? petData['vetId'] : null;
  Map<String, dynamic>? vet;
  if (vetId != null && vetId.toString().isNotEmpty) {
    final vetResult = await _db.execute(
      Sql.named('SELECT * FROM vets WHERE id = @id'),
      parameters: {'id': int.tryParse(vetId.toString()) ?? 0},
    );
    if (vetResult.isNotEmpty) {
      vet = _vetRowToMap(vetResult.first);
    }
  }

  _jsonResponse(request, 200, {
    'pet': petData,
    'health_entries': healthEntries,
    'vet': vet,
  });
}

// ── Helpers ──────────────────────────────────────────────────

Map<String, dynamic> _vetRowToMap(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'name': cols['name'].toString(),
    'phone': cols['phone'].toString(),
    'email': cols['email'].toString(),
    'website': cols['website'].toString(),
    'address': cols['address'].toString(),
    'notes': cols['notes'].toString(),
    'created_at': cols['created_at'].toString(),
    'updated_at': cols['updated_at'].toString(),
  };
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
