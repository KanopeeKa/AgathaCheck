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

  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN first_name VARCHAR(100) DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN last_name VARCHAR(100) DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN category VARCHAR(50) DEFAULT 'pet_guardian';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN bio TEXT DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN photo_url TEXT DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('users table ready');

  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE shared_pets ADD COLUMN user_id INTEGER DEFAULT NULL;
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('shared_pets user_id column ready');

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

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      pet_id VARCHAR(255),
      health_entry_id VARCHAR(255),
      title VARCHAR(500) NOT NULL,
      message TEXT NOT NULL DEFAULT '',
      type VARCHAR(50) NOT NULL DEFAULT 'reminder',
      is_read BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('notifications table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS notification_preferences (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      email_reminders_enabled BOOLEAN NOT NULL DEFAULT FALSE,
      reminder_days_before INTEGER NOT NULL DEFAULT 1,
      notify_completed BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  await _db.execute(Sql('''
    ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS notify_completed BOOLEAN NOT NULL DEFAULT TRUE
  '''));
  await _db.execute(Sql('''
    ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS muted_pet_ids TEXT NOT NULL DEFAULT ''
  '''));
  print('notification_preferences table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS weight_entries (
      id SERIAL PRIMARY KEY,
      pet_id VARCHAR(255) NOT NULL,
      date DATE NOT NULL,
      weight DOUBLE PRECISION NOT NULL,
      notes TEXT DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('weight_entries table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS pet_access (
      id SERIAL PRIMARY KEY,
      pet_id VARCHAR(255) NOT NULL,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role VARCHAR(20) NOT NULL DEFAULT 'shared',
      invited_by INTEGER REFERENCES users(id),
      share_code VARCHAR(12) UNIQUE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(pet_id, user_id)
    )
  '''));
  print('pet_access table ready');

  await _db.execute(Sql('''
    ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS repeat_end_date DATE
  '''));

  await _db.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_frequency_check;
      ALTER TABLE health_entries ADD CONSTRAINT health_entries_frequency_check
        CHECK (frequency = ANY (ARRAY['once','daily','weekly','monthly','custom']));
      UPDATE health_entries SET type = 'vet_visit' WHERE type = 'vaccine';
      ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_type_check;
      ALTER TABLE health_entries ADD CONSTRAINT health_entries_type_check
        CHECK (type = ANY (ARRAY['medication','preventive','vet_visit','procedure']));
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('health_entries schema updated');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS health_event_photos (
      id SERIAL PRIMARY KEY,
      event_id VARCHAR(255) NOT NULL,
      photo_path TEXT NOT NULL,
      caption TEXT DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('health_event_photos table ready');

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS health_issues (
      id SERIAL PRIMARY KEY,
      pet_id VARCHAR(255) NOT NULL,
      title VARCHAR(255) NOT NULL,
      description TEXT DEFAULT '',
      start_date DATE,
      end_date DATE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));

  await _db.execute(Sql('''
    CREATE TABLE IF NOT EXISTS health_issue_events (
      health_issue_id INT NOT NULL REFERENCES health_issues(id) ON DELETE CASCADE,
      health_entry_id UUID NOT NULL,
      PRIMARY KEY (health_issue_id, health_entry_id)
    )
  '''));

  await _db.execute(Sql('''
    ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS health_issue_id INT REFERENCES health_issues(id) ON DELETE SET NULL
  '''));

  await _db.execute(Sql('ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS start_date DATE'));
  await _db.execute(Sql('ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS end_date DATE'));

  print('health_issues tables ready');

  final uploadsDir = Directory('uploads');
  if (!uploadsDir.existsSync()) {
    uploadsDir.createSync(recursive: true);
  }

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
      } else if (path.startsWith('/uploads/')) {
        await _serveUpload(request);
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
  } else if (path == '/api/auth/me/photo' && method == 'POST') {
    await _uploadUserPhoto(request);
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
  // Notifications
  else if (path == '/api/notifications' && method == 'GET') {
    await _getNotifications(request);
  } else if (path == '/api/notifications/unread-count' && method == 'GET') {
    await _getUnreadCount(request);
  } else if (path == '/api/notifications/read-all' && method == 'PUT') {
    await _markAllNotificationsRead(request);
  } else if (path == '/api/notifications/preferences' && method == 'GET') {
    await _getNotificationPreferences(request);
  } else if (path == '/api/notifications/preferences' && method == 'PUT') {
    await _updateNotificationPreferences(request);
  } else if (path == '/api/notifications/check-due' && method == 'POST') {
    await _checkDueNotifications(request);
  } else if (RegExp(r'^/api/notifications/\d+/read$').hasMatch(path) && method == 'PUT') {
    await _markNotificationRead(request);
  }
  // Weight entries
  else if (path == '/api/weight-entries/latest' && method == 'GET') {
    await _getLatestWeight(request);
  } else if (path == '/api/weight-entries' && method == 'GET') {
    await _getWeightEntries(request);
  } else if (path == '/api/weight-entries' && method == 'POST') {
    await _createWeightEntry(request);
  } else if (RegExp(r'^/api/weight-entries/[^/]+$').hasMatch(path) &&
      method == 'PUT') {
    await _updateWeightEntry(request);
  } else if (RegExp(r'^/api/weight-entries/[^/]+$').hasMatch(path) &&
      method == 'DELETE') {
    await _deleteWeightEntry(request);
  }
  // Health event photos
  else if (RegExp(r'^/api/health-entries/[^/]+/photos$').hasMatch(path) &&
      method == 'GET') {
    await _getEventPhotos(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+/photos$').hasMatch(path) &&
      method == 'POST') {
    await _uploadEventPhoto(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+/photos/\d+$').hasMatch(path) &&
      method == 'DELETE') {
    await _deleteEventPhoto(request);
  }
  // Sharing
  else if (path == '/api/share' && method == 'POST') {
    await _createShare(request);
  } else if (RegExp(r'^/api/share/[^/]+/accept$').hasMatch(path) && method == 'POST') {
    await _acceptShare(request);
  } else if (RegExp(r'^/api/share/[^/]+$').hasMatch(path) && method == 'GET') {
    await _getShare(request);
  }
  // Pet data cleanup
  else if (RegExp(r'^/api/pets/[^/]+/data$').hasMatch(path) && method == 'DELETE') {
    await _deletePetData(request);
  }
  // Pet access management
  else if (RegExp(r'^/api/pets/[^/]+/access$').hasMatch(path) && method == 'GET') {
    await _getPetAccess(request);
  } else if (RegExp(r'^/api/pets/[^/]+/access/\d+/role$').hasMatch(path) && method == 'PUT') {
    await _updatePetAccessRole(request);
  } else if (RegExp(r'^/api/pets/[^/]+/access/\d+$').hasMatch(path) && method == 'DELETE') {
    await _deletePetAccess(request);
  }
  // Health issues
  else if (path == '/api/health-issues' && method == 'GET') {
    await _getHealthIssues(request);
  } else if (path == '/api/health-issues' && method == 'POST') {
    await _createHealthIssue(request);
  } else if (RegExp(r'^/api/health-issues/\d+/events/[a-f0-9\-]+$').hasMatch(path) && method == 'DELETE') {
    await _unlinkHealthIssueEvent(request);
  } else if (RegExp(r'^/api/health-issues/\d+/events$').hasMatch(path) && method == 'POST') {
    await _linkHealthIssueEvent(request);
  } else if (RegExp(r'^/api/health-issues/\d+$').hasMatch(path) && method == 'PUT') {
    await _updateHealthIssue(request);
  } else if (RegExp(r'^/api/health-issues/\d+$').hasMatch(path) && method == 'DELETE') {
    await _deleteHealthIssue(request);
  } else {
    _jsonResponse(request, 404, {'error': 'Not found'});
  }
}

// ── User JSON helper ─────────────────────────────────────────

Map<String, dynamic> _userToJson(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'email': cols['email'].toString(),
    'name': (cols['name'] ?? '').toString(),
    'first_name': (cols['first_name'] ?? '').toString(),
    'last_name': (cols['last_name'] ?? '').toString(),
    'category': (cols['category'] ?? 'pet_guardian').toString(),
    'bio': (cols['bio'] ?? '').toString(),
    'photo_url': (cols['photo_url'] ?? '').toString(),
    'created_at': cols['created_at'].toString(),
    'updated_at': cols['updated_at'].toString(),
  };
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
      RETURNING id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at
    '''),
    parameters: {'email': email, 'hash': hash, 'name': name},
  );

  final userJson = _userToJson(result.first);
  final userId = int.parse(userJson['id']);
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
    'user': userJson,
    'access_token': accessToken,
    'refresh_token': refreshToken,
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
    Sql.named('SELECT id, email, password_hash, name, first_name, last_name, category, bio, photo_url, created_at, updated_at FROM users WHERE email = @email'),
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

  final userJson = _userToJson(result.first);
  _jsonResponse(request, 200, {
    'user': userJson,
    'access_token': accessToken,
    'refresh_token': refreshToken,
  });
}

Future<void> _authRefresh(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final refreshToken = (body['refresh_token'] ?? body['refreshToken']) as String? ?? '';
  if (refreshToken.isEmpty) {
    _jsonResponse(request, 400, {'error': 'refresh_token is required'});
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
    'access_token': newAccessToken,
  });
}

Future<void> _authLogout(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final refreshToken = (body['refresh_token'] ?? body['refreshToken']) as String? ?? '';
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
    Sql.named('SELECT id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at FROM users WHERE id = @id'),
    parameters: {'id': int.parse(userId)},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  _jsonResponse(request, 200, _userToJson(result.first));
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
  final firstName = (body['first_name'] as String? ?? '').trim();
  final lastName = (body['last_name'] as String? ?? '').trim();
  final category = body['category'] as String? ?? 'pet_guardian';
  final bio = body['bio'] as String? ?? '';
  final name = '$firstName $lastName'.trim();

  final result = await _db.execute(
    Sql.named('''
      UPDATE users SET
        name = @name,
        first_name = @firstName,
        last_name = @lastName,
        category = @category,
        bio = @bio,
        updated_at = NOW()
      WHERE id = @id
      RETURNING id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at
    '''),
    parameters: {
      'id': userId,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'category': category,
      'bio': bio,
    },
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  _jsonResponse(request, 200, _userToJson(result.first));
}

Future<void> _uploadUserPhoto(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());

  final contentType = request.headers.contentType;
  if (contentType == null || contentType.mimeType != 'multipart/form-data') {
    _jsonResponse(request, 400, {'error': 'Expected multipart/form-data'});
    return;
  }

  final boundary = contentType.parameters['boundary'];
  if (boundary == null) {
    _jsonResponse(request, 400, {'error': 'Missing boundary'});
    return;
  }

  final rawBytes = await request.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
  if (rawBytes.length > 2 * 1024 * 1024) {
    _jsonResponse(request, 400, {'error': 'File too large (max 2MB)'});
    return;
  }

  final parts = _parseMultipart(rawBytes, boundary);

  List<int>? fileBytes;
  String? fileName;

  for (final part in parts) {
    if (part.name == 'photo' && part.bytes != null) {
      fileBytes = part.bytes;
      fileName = part.filename ?? 'avatar.jpg';
    }
  }

  if (fileBytes == null || fileBytes.isEmpty) {
    _jsonResponse(request, 400, {'error': 'No photo file provided'});
    return;
  }

  final ext = fileName != null && fileName.contains('.')
      ? fileName.substring(fileName.lastIndexOf('.'))
      : '.jpg';
  final ts = DateTime.now().millisecondsSinceEpoch;
  final uniqueName = '${userId}_$ts$ext';

  final avatarDir = Directory('uploads/avatars');
  if (!avatarDir.existsSync()) {
    avatarDir.createSync(recursive: true);
  }

  final filePath = 'uploads/avatars/$uniqueName';
  File(filePath).writeAsBytesSync(fileBytes);

  final result = await _db.execute(
    Sql.named('''
      UPDATE users SET photo_url = @photoUrl, updated_at = NOW()
      WHERE id = @id
      RETURNING id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at
    '''),
    parameters: {'id': userId, 'photoUrl': filePath},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User not found'});
    return;
  }

  _jsonResponse(request, 200, _userToJson(result.first));
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

  var query = 'SELECT he.*, hi.title AS health_issue_title FROM health_entries he LEFT JOIN health_issues hi ON he.health_issue_id = hi.id WHERE 1=1';
  final params = <String, dynamic>{};

  if (petId != null && petId.isNotEmpty) {
    query += ' AND he.pet_id = @petId';
    params['petId'] = petId;
  }
  if (type != null && type.isNotEmpty) {
    query += ' AND he.type = @type';
    params['type'] = type;
  }

  query += ' ORDER BY he.next_due_date ASC';

  final result = await _db.execute(Sql.named(query),
      parameters: params.isEmpty ? null : params);
  final entries = result.map(_rowToMap).toList();
  _jsonResponse(request, 200, entries);
}

Future<void> _getHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('SELECT he.*, hi.title AS health_issue_title FROM health_entries he LEFT JOIN health_issues hi ON he.health_issue_id = hi.id WHERE he.id = @id'),
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
  final repeatEndDate = body['repeat_end_date'] as String?;
  final startDate = body['start_date'] as String? ?? '';
  final nextDueDate = body['next_due_date'] as String? ?? startDate;
  final notes = body['notes'] as String? ?? '';
  final petId = body['pet_id'] as String? ?? '';
  final healthIssueId = body['health_issue_id'] != null ? int.tryParse(body['health_issue_id'].toString()) : null;

  if (name.isEmpty || type.isEmpty || frequency.isEmpty || startDate.isEmpty) {
    _jsonResponse(
        request, 400, {'error': 'name, type, frequency, start_date required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO health_entries (pet_id, name, type, dosage, frequency, frequency_days, repeat_end_date, start_date, next_due_date, notes, health_issue_id)
      VALUES (@petId, @name, @type, @dosage, @frequency, @frequencyDays, ${repeatEndDate != null ? '@repeatEndDate::date' : 'NULL'}, @startDate::date, @nextDueDate::timestamptz, @notes, ${healthIssueId != null ? '@healthIssueId' : 'NULL'})
      RETURNING *
    '''),
    parameters: {
      'petId': petId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'frequencyDays': frequencyDays,
      if (repeatEndDate != null) 'repeatEndDate': repeatEndDate,
      'startDate': startDate,
      'nextDueDate': nextDueDate,
      'notes': notes,
      if (healthIssueId != null) 'healthIssueId': healthIssueId,
    },
  );

  if (healthIssueId != null) {
    final createdId = result.first.toColumnMap()['id'].toString();
    if (createdId.isNotEmpty) {
      await _db.execute(
        Sql.named('''
          INSERT INTO health_issue_events (health_issue_id, health_entry_id)
          VALUES (@healthIssueId, @entryId::uuid)
          ON CONFLICT DO NOTHING
        '''),
        parameters: {'healthIssueId': healthIssueId, 'entryId': createdId},
      );
    }
  }

  final createdRow = _rowToMap(result.first);

  final parsedNextDue = DateTime.tryParse(nextDueDate);
  if (frequency == 'once' && parsedNextDue != null && parsedNextDue.year >= 9999) {
    final payload = await _authenticateRequest(request);
    if (payload != null) {
      final userId = int.parse(payload['sub'].toString());
      final prefResult = await _db.execute(
        Sql.named('SELECT notify_completed FROM notification_preferences WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      final notifyCompleted = prefResult.isEmpty || (prefResult.first.toColumnMap()['notify_completed'] as bool? ?? true);
      if (notifyCompleted) {
        final petName = body['pet_name'] as String? ?? '';
        final petPrefix = petName.isNotEmpty ? '$petName - ' : '';
        await _db.execute(
          Sql.named('''
            INSERT INTO notifications (user_id, pet_id, health_entry_id, title, message, type)
            VALUES (@userId, @petId, @entryId, @title, @message, 'completed')
          '''),
          parameters: {
            'userId': userId,
            'petId': petId,
            'entryId': createdRow['id'].toString(),
            'title': '${petPrefix}Completed: $name',
            'message': '$name has been completed',
          },
        );
      }
    }
  }

  _jsonResponse(request, 201, createdRow);
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

  final hasRepeatEndDate = body.containsKey('repeat_end_date');
  final repeatEndDateVal = hasRepeatEndDate ? body['repeat_end_date'] : row['repeat_end_date'];

  final hasHealthIssueId = body.containsKey('health_issue_id');
  final newHealthIssueId = hasHealthIssueId
      ? (body['health_issue_id'] != null ? int.tryParse(body['health_issue_id'].toString()) : null)
      : (row['health_issue_id'] != null ? int.tryParse(row['health_issue_id'].toString()) : null);
  final oldHealthIssueId = row['health_issue_id'] != null ? int.tryParse(row['health_issue_id'].toString()) : null;

  final result = await _db.execute(
    Sql.named('''
      UPDATE health_entries SET
        name = @name, type = @type, dosage = @dosage,
        frequency = @frequency, frequency_days = @frequencyDays,
        repeat_end_date = ${repeatEndDateVal != null ? '@repeatEndDate::date' : 'NULL'},
        start_date = @startDate::date, next_due_date = @nextDueDate::timestamptz,
        notes = @notes, health_issue_id = ${newHealthIssueId != null ? '@healthIssueId' : 'NULL'},
        updated_at = NOW()
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
      if (repeatEndDateVal != null) 'repeatEndDate': repeatEndDateVal.toString(),
      'startDate': body['start_date'] ?? row['start_date'],
      'nextDueDate': body['next_due_date'] ?? row['next_due_date'],
      'notes': body['notes'] ?? row['notes'],
      if (newHealthIssueId != null) 'healthIssueId': newHealthIssueId,
    },
  );

  if (hasHealthIssueId) {
    if (oldHealthIssueId != null && oldHealthIssueId != newHealthIssueId) {
      await _db.execute(
        Sql.named('DELETE FROM health_issue_events WHERE health_issue_id = @oldId AND health_entry_id = @entryId::uuid'),
        parameters: {'oldId': oldHealthIssueId, 'entryId': id},
      );
    }
    if (newHealthIssueId != null && newHealthIssueId != oldHealthIssueId) {
      await _db.execute(
        Sql.named('INSERT INTO health_issue_events (health_issue_id, health_entry_id) VALUES (@newId, @entryId::uuid) ON CONFLICT DO NOTHING'),
        parameters: {'newId': newHealthIssueId, 'entryId': id},
      );
    }
  }

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
  final repeatEndDateStr = row['repeat_end_date']?.toString();
  final repeatEndDate = repeatEndDateStr != null ? DateTime.tryParse(repeatEndDateStr) : null;
  DateTime nextDue;

  switch (frequency) {
    case 'once':
      nextDue = DateTime(9999, 12, 31);
      break;
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
      nextDue = currentDue;
  }

  if (repeatEndDate != null && nextDue.isAfter(repeatEndDate)) {
    nextDue = currentDue;
  }

  final updated = await _db.execute(
    Sql.named('''
      UPDATE health_entries SET next_due_date = @nextDue, updated_at = NOW()
      WHERE id = @id RETURNING *
    '''),
    parameters: {'id': id, 'nextDue': nextDue.toIso8601String()},
  );

  if (frequency == 'once' && nextDue.year >= 9999) {
    final payload = await _authenticateRequest(request);
    if (payload != null) {
      final userId = int.parse(payload['sub'].toString());
      final prefResult = await _db.execute(
        Sql.named('SELECT notify_completed FROM notification_preferences WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      final notifyCompleted = prefResult.isEmpty || (prefResult.first.toColumnMap()['notify_completed'] as bool? ?? true);
      if (notifyCompleted) {
        final entryName = row['name'].toString();
        final petId = row['pet_id'].toString();
        final petName = body?['pet_name'] as String? ?? '';
        final petPrefix = petName.isNotEmpty ? '$petName - ' : '';
        await _db.execute(
          Sql.named('''
            INSERT INTO notifications (user_id, pet_id, health_entry_id, title, message, type)
            VALUES (@userId, @petId, @entryId, @title, @message, 'completed')
          '''),
          parameters: {
            'userId': userId,
            'petId': petId,
            'entryId': id,
            'title': '${petPrefix}Completed: $entryName',
            'message': '$entryName has been completed',
          },
        );
      }
    }
  }

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

// ── Weight entries ───────────────────────────────────────────

Future<void> _getWeightEntries(HttpRequest request) async {
  final petId = request.uri.queryParameters['pet_id'];

  var query = 'SELECT * FROM weight_entries WHERE 1=1';
  final params = <String, dynamic>{};

  if (petId != null && petId.isNotEmpty) {
    query += ' AND pet_id = @petId';
    params['petId'] = petId;
  }

  query += ' ORDER BY date ASC';

  final result = await _db.execute(Sql.named(query),
      parameters: params.isEmpty ? null : params);
  final entries = result.map(_weightRowToMap).toList();
  _jsonResponse(request, 200, entries);
}

Future<void> _createWeightEntry(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final petId = body['pet_id'] as String? ?? '';
  final date = body['date'] as String? ?? '';
  final weight = body['weight'];
  final notes = body['notes'] as String? ?? '';

  if (petId.isEmpty || date.isEmpty || weight == null) {
    _jsonResponse(request, 400, {'error': 'pet_id, date, and weight are required'});
    return;
  }

  final weightValue = (weight is num) ? weight.toDouble() : double.tryParse(weight.toString());
  if (weightValue == null || weightValue <= 0) {
    _jsonResponse(request, 400, {'error': 'weight must be a positive number'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO weight_entries (pet_id, date, weight, notes)
      VALUES (@petId, @date::date, @weight, @notes)
      RETURNING *
    '''),
    parameters: {
      'petId': petId,
      'date': date,
      'weight': weightValue,
      'notes': notes,
    },
  );

  _jsonResponse(request, 201, _weightRowToMap(result.first));
}

Future<void> _updateWeightEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _db.execute(
    Sql.named('SELECT * FROM weight_entries WHERE id = @id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Weight entry not found'});
    return;
  }

  final row = _weightRowToMap(existing.first);

  final weight = body['weight'];
  final weightValue = weight != null
      ? ((weight is num) ? weight.toDouble() : double.tryParse(weight.toString()))
      : double.tryParse(row['weight'].toString());

  final result = await _db.execute(
    Sql.named('''
      UPDATE weight_entries SET
        date = @date::date, weight = @weight, notes = @notes
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'id': int.tryParse(id) ?? 0,
      'date': body['date'] ?? row['date'],
      'weight': weightValue,
      'notes': body['notes'] ?? row['notes'],
    },
  );

  _jsonResponse(request, 200, _weightRowToMap(result.first));
}

Future<void> _deleteWeightEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _db.execute(
    Sql.named('DELETE FROM weight_entries WHERE id = @id RETURNING id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Weight entry not found'});
    return;
  }

  _jsonResponse(request, 200, {'deleted': true});
}

Future<void> _getLatestWeight(HttpRequest request) async {
  final petId = request.uri.queryParameters['pet_id'];

  if (petId == null || petId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'pet_id is required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('SELECT * FROM weight_entries WHERE pet_id = @petId ORDER BY date DESC LIMIT 1'),
    parameters: {'petId': petId},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'No weight entries found'});
    return;
  }

  _jsonResponse(request, 200, _weightRowToMap(result.first));
}

// ── Health event photos ──────────────────────────────────────

Future<void> _getEventPhotos(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final eventId = segments[segments.length - 2];
  final result = await _db.execute(
    Sql.named('SELECT * FROM health_event_photos WHERE event_id = @eventId ORDER BY created_at ASC'),
    parameters: {'eventId': eventId},
  );
  final photos = result.map((r) => {
    'id': r[0],
    'event_id': r[1].toString(),
    'photo_path': r[2].toString(),
    'caption': r[3].toString(),
    'created_at': r[4].toString(),
  }).toList();
  _jsonResponse(request, 200, photos);
}

Future<void> _uploadEventPhoto(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final eventId = segments[segments.length - 2];

  final contentType = request.headers.contentType;
  if (contentType == null || contentType.mimeType != 'multipart/form-data') {
    _jsonResponse(request, 400, {'error': 'Expected multipart/form-data'});
    return;
  }

  final boundary = contentType.parameters['boundary'];
  if (boundary == null) {
    _jsonResponse(request, 400, {'error': 'Missing boundary'});
    return;
  }

  final countResult = await _db.execute(
    Sql.named('SELECT COUNT(*) FROM health_event_photos WHERE event_id = @eventId'),
    parameters: {'eventId': eventId},
  );
  final currentCount = countResult.first[0] as int;
  if (currentCount >= 4) {
    _jsonResponse(request, 400, {'error': 'Maximum 4 photos per event'});
    return;
  }

  final rawBytes = await request.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
  if (rawBytes.length > 2 * 1024 * 1024) {
    _jsonResponse(request, 400, {'error': 'File too large (max 2MB)'});
    return;
  }

  final parts = _parseMultipart(rawBytes, boundary);

  List<int>? fileBytes;
  String? fileName;
  String caption = '';

  for (final part in parts) {
    if (part.name == 'photo' && part.bytes != null) {
      fileBytes = part.bytes;
      fileName = part.filename ?? 'photo.jpg';
    } else if (part.name == 'caption') {
      caption = utf8.decode(part.bytes ?? []);
    }
  }

  if (fileBytes == null || fileBytes.isEmpty) {
    _jsonResponse(request, 400, {'error': 'No photo file provided'});
    return;
  }

  final ext = fileName != null && fileName.contains('.')
      ? fileName.substring(fileName.lastIndexOf('.'))
      : '.jpg';
  final ts = DateTime.now().millisecondsSinceEpoch;
  final rng = Random.secure();
  final uniqueName = '${eventId}_${ts}_${rng.nextInt(9999)}$ext';

  final eventDir = Directory('uploads/health/$eventId');
  if (!eventDir.existsSync()) {
    eventDir.createSync(recursive: true);
  }

  final filePath = 'uploads/health/$eventId/$uniqueName';
  File(filePath).writeAsBytesSync(fileBytes);

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO health_event_photos (event_id, photo_path, caption)
      VALUES (@eventId, @photoPath, @caption)
      RETURNING *
    '''),
    parameters: {
      'eventId': eventId,
      'photoPath': filePath,
      'caption': caption,
    },
  );

  final row = result.first;
  _jsonResponse(request, 201, {
    'id': row[0],
    'event_id': row[1].toString(),
    'photo_path': row[2].toString(),
    'caption': row[3].toString(),
    'created_at': row[4].toString(),
  });
}

Future<void> _deleteEventPhoto(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final photoId = int.tryParse(segments.last);
  if (photoId == null) {
    _jsonResponse(request, 400, {'error': 'Invalid photo ID'});
    return;
  }

  final result = await _db.execute(
    Sql.named('SELECT photo_path FROM health_event_photos WHERE id = @id'),
    parameters: {'id': photoId},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Photo not found'});
    return;
  }

  final filePath = result.first[0].toString();
  final file = File(filePath);
  if (file.existsSync()) {
    file.deleteSync();
  }

  await _db.execute(
    Sql.named('DELETE FROM health_event_photos WHERE id = @id'),
    parameters: {'id': photoId},
  );

  _jsonResponse(request, 200, {'deleted': true});
}

Future<void> _serveUpload(HttpRequest request) async {
  final path = request.uri.path.substring(1);
  final file = File(path);
  if (!file.existsSync()) {
    request.response.statusCode = 404;
    request.response.write('Not found');
    await request.response.close();
    return;
  }

  final ext = path.contains('.') ? path.substring(path.lastIndexOf('.') + 1).toLowerCase() : '';
  final mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
  };
  request.response.headers.set('Content-Type', mimeTypes[ext] ?? 'application/octet-stream');
  request.response.headers.set('Cache-Control', 'public, max-age=86400');
  await request.response.addStream(file.openRead());
  await request.response.close();
}

class _MultipartPart {
  final String? name;
  final String? filename;
  final List<int>? bytes;
  _MultipartPart({this.name, this.filename, this.bytes});
}

List<_MultipartPart> _parseMultipart(List<int> body, String boundary) {
  final parts = <_MultipartPart>[];
  final boundaryBytes = utf8.encode('--$boundary');

  int findBytes(List<int> haystack, List<int> needle, int start) {
    for (var i = start; i <= haystack.length - needle.length; i++) {
      var found = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  var pos = findBytes(body, boundaryBytes, 0);
  if (pos == -1) return parts;

  while (true) {
    pos += boundaryBytes.length;
    if (pos + 2 >= body.length) break;
    if (body[pos] == 0x2D && body[pos + 1] == 0x2D) break;

    while (pos < body.length && (body[pos] == 0x0D || body[pos] == 0x0A)) pos++;

    final headerEnd = findBytes(body, utf8.encode('\r\n\r\n'), pos);
    if (headerEnd == -1) break;

    final headerStr = utf8.decode(body.sublist(pos, headerEnd));
    pos = headerEnd + 4;

    final nextBoundary = findBytes(body, boundaryBytes, pos);
    if (nextBoundary == -1) break;

    var endPos = nextBoundary;
    if (endPos >= 2 && body[endPos - 2] == 0x0D && body[endPos - 1] == 0x0A) {
      endPos -= 2;
    }
    final dataBytes = body.sublist(pos, endPos);

    String? name;
    String? filename;
    final dispMatch = RegExp(r'name="([^"]*)"').firstMatch(headerStr);
    if (dispMatch != null) name = dispMatch.group(1);
    final fileMatch = RegExp(r'filename="([^"]*)"').firstMatch(headerStr);
    if (fileMatch != null) filename = fileMatch.group(1);

    parts.add(_MultipartPart(name: name, filename: filename, bytes: dataBytes));
    pos = nextBoundary;
  }

  return parts;
}

// ── Sharing ──────────────────────────────────────────────────

String _generateShareCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
  final rng = Random.secure();
  return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
}

Future<void> _createShare(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final authUserId = int.parse(payload['sub'].toString());

  final body = await _readJson(request);
  if (body == null) return;

  final petData = body['pet'] as Map<String, dynamic>?;
  final petId = body['pet_id'] as String? ?? '';

  if (petData == null || petId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'pet and pet_id required'});
    return;
  }

  await _db.execute(
    Sql.named('''
      INSERT INTO pet_access (pet_id, user_id, role)
      VALUES (@petId, @userId, 'guardian')
      ON CONFLICT (pet_id, user_id) DO UPDATE SET role = 'guardian'
    '''),
    parameters: {'petId': petId, 'userId': authUserId},
  );

  final existingAccess = await _db.execute(
    Sql.named('SELECT share_code FROM pet_access WHERE pet_id = @petId AND user_id = @userId AND share_code IS NOT NULL'),
    parameters: {'petId': petId, 'userId': authUserId},
  );

  String code;
  if (existingAccess.isNotEmpty && existingAccess.first.toColumnMap()['share_code'] != null) {
    code = existingAccess.first.toColumnMap()['share_code'].toString();
  } else {
    code = _generateShareCode();
    await _db.execute(
      Sql.named('UPDATE pet_access SET share_code = @code WHERE pet_id = @petId AND user_id = @userId'),
      parameters: {'code': code, 'petId': petId, 'userId': authUserId},
    );
  }

  final existingShared = await _db.execute(
    Sql.named('SELECT id FROM shared_pets WHERE pet_id = @petId'),
    parameters: {'petId': petId},
  );

  if (existingShared.isNotEmpty) {
    await _db.execute(
      Sql.named('''
        UPDATE shared_pets SET pet_data = @petData::jsonb, updated_at = NOW(), user_id = @userId, share_code = @code
        WHERE pet_id = @petId
      '''),
      parameters: {
        'petId': petId,
        'petData': json.encode(petData),
        'userId': authUserId,
        'code': code,
      },
    );
  } else {
    await _db.execute(
      Sql.named('''
        INSERT INTO shared_pets (share_code, pet_data, pet_id, user_id)
        VALUES (@code, @petData::jsonb, @petId, @userId)
      '''),
      parameters: {
        'code': code,
        'petData': json.encode(petData),
        'petId': petId,
        'userId': authUserId,
      },
    );
  }

  _jsonResponse(request, 200, {'share_code': code});
}

Future<void> _getShare(HttpRequest request) async {
  final code = request.uri.pathSegments.last;

  final result = await _db.execute(
    Sql.named('SELECT * FROM shared_pets WHERE share_code = @code'),
    parameters: {'code': code},
  );

  Map<String, dynamic>? guardianInfo;
  final accessResult = await _db.execute(
    Sql.named('''
      SELECT pa.*, u.first_name, u.last_name, u.category, u.bio, u.photo_url
      FROM pet_access pa
      JOIN users u ON u.id = pa.user_id
      WHERE pa.share_code = @code
    '''),
    parameters: {'code': code},
  );

  if (result.isEmpty && accessResult.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Share not found'});
    return;
  }

  if (accessResult.isNotEmpty) {
    final aCols = accessResult.first.toColumnMap();
    guardianInfo = {
      'user_id': aCols['user_id'].toString(),
      'first_name': (aCols['first_name'] ?? '').toString(),
      'last_name': (aCols['last_name'] ?? '').toString(),
      'category': (aCols['category'] ?? 'pet_guardian').toString(),
      'bio': (aCols['bio'] ?? '').toString(),
      'photo_url': (aCols['photo_url'] ?? '').toString(),
    };
  }

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Share not found'});
    return;
  }

  final cols = result.first.toColumnMap();
  final petData = cols['pet_data'];
  final petId = cols['pet_id'].toString();
  final shareUserId = cols['user_id'];

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

  Map<String, dynamic>? owner = guardianInfo;
  if (owner == null && shareUserId != null) {
    final ownerResult = await _db.execute(
      Sql.named('SELECT id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at FROM users WHERE id = @id'),
      parameters: {'id': shareUserId},
    );
    if (ownerResult.isNotEmpty) {
      final ownerRow = ownerResult.first.toColumnMap();
      owner = {
        'user_id': ownerRow['id'].toString(),
        'first_name': (ownerRow['first_name'] ?? '').toString(),
        'last_name': (ownerRow['last_name'] ?? '').toString(),
        'category': (ownerRow['category'] ?? 'pet_guardian').toString(),
        'bio': (ownerRow['bio'] ?? '').toString(),
        'photo_url': (ownerRow['photo_url'] ?? '').toString(),
      };
    }
  }

  _jsonResponse(request, 200, {
    'pet': petData,
    'health_entries': healthEntries,
    'vet': vet,
    'owner': owner,
    'guardian': guardianInfo,
  });
}

Future<void> _acceptShare(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final userId = int.parse(payload['sub'].toString());

  final segments = request.uri.pathSegments;
  final code = segments[segments.length - 2];

  final accessResult = await _db.execute(
    Sql.named('SELECT pet_id, user_id FROM pet_access WHERE share_code = @code'),
    parameters: {'code': code},
  );

  if (accessResult.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Share code not found'});
    return;
  }

  final accessCols = accessResult.first.toColumnMap();
  final petId = accessCols['pet_id'].toString();
  final guardianUserId = accessCols['user_id'] as int;

  if (guardianUserId == userId) {
    _jsonResponse(request, 400, {'error': 'You are already a guardian of this pet'});
    return;
  }

  await _db.execute(
    Sql.named('''
      INSERT INTO pet_access (pet_id, user_id, role, invited_by)
      VALUES (@petId, @userId, 'shared', @invitedBy)
      ON CONFLICT (pet_id, user_id) DO NOTHING
    '''),
    parameters: {
      'petId': petId,
      'userId': userId,
      'invitedBy': guardianUserId,
    },
  );

  _jsonResponse(request, 200, {'pet_id': petId, 'message': 'Access granted'});
}

Future<Map<String, dynamic>> _petAccessRowToJson(ResultRow row) async {
  final cols = row.toColumnMap();
  final userId = cols['user_id'] as int;

  final userResult = await _db.execute(
    Sql.named('SELECT id, first_name, last_name, category, bio, photo_url FROM users WHERE id = @id'),
    parameters: {'id': userId},
  );

  Map<String, dynamic> userInfo = {};
  if (userResult.isNotEmpty) {
    final u = userResult.first.toColumnMap();
    final firstName = (u['first_name'] ?? '').toString();
    final lastName = (u['last_name'] ?? '').toString();
    final displayName = '$firstName $lastName'.trim();
    final initials = ((firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
    userInfo = {
      'id': u['id'].toString(),
      'first_name': firstName,
      'last_name': lastName,
      'category': (u['category'] ?? 'pet_guardian').toString(),
      'bio': (u['bio'] ?? '').toString(),
      'photo_url': (u['photo_url'] ?? '').toString(),
      'display_name': displayName.isNotEmpty ? displayName : 'User',
      'initials': initials.isNotEmpty ? initials : 'U',
    };
  }

  return {
    'id': cols['id'].toString(),
    'pet_id': cols['pet_id'].toString(),
    'user_id': cols['user_id'].toString(),
    'role': cols['role'].toString(),
    'invited_by': cols['invited_by']?.toString(),
    'share_code': cols['share_code']?.toString(),
    'created_at': cols['created_at'].toString(),
    'user': userInfo,
  };
}

Future<void> _deletePetData(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final petId = segments[2];

  try {
    await _db.execute(
      Sql.named('DELETE FROM health_issue_events WHERE health_issue_id IN (SELECT id FROM health_issues WHERE pet_id = @petId)'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('UPDATE health_entries SET health_issue_id = NULL WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM health_issues WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    final photoRows = await _db.execute(
      Sql.named('SELECT p.id, p.photo_path FROM health_event_photos p INNER JOIN health_entries e ON p.event_id = e.id::text WHERE e.pet_id = @petId'),
      parameters: {'petId': petId},
    );
    for (final row in photoRows) {
      final cols = row.toColumnMap();
      final photoPath = cols['photo_path']?.toString();
      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    await _db.execute(
      Sql.named('DELETE FROM health_event_photos WHERE event_id IN (SELECT id::text FROM health_entries WHERE pet_id = @petId)'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM health_entries WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM weight_entries WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM notifications WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM pet_access WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _db.execute(
      Sql.named('DELETE FROM shared_pets WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    _jsonResponse(request, 200, {'deleted': true, 'pet_id': petId});
  } catch (e) {
    print('Error deleting pet data for $petId: $e');
    _jsonResponse(request, 500, {'error': 'Failed to delete pet data'});
  }
}

Future<void> _getPetAccess(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final userId = int.parse(payload['sub'].toString());

  final segments = request.uri.pathSegments;
  final petId = segments[segments.length - 2];

  final callerAccess = await _db.execute(
    Sql.named('SELECT role, invited_by FROM pet_access WHERE pet_id = @petId AND user_id = @userId'),
    parameters: {'petId': petId, 'userId': userId},
  );

  if (callerAccess.isEmpty) {
    _jsonResponse(request, 403, {'error': 'No access to this pet'});
    return;
  }

  final callerCols = callerAccess.first.toColumnMap();
  final callerRole = callerCols['role'].toString();

  List<Map<String, dynamic>> accessList;

  if (callerRole == 'guardian') {
    final result = await _db.execute(
      Sql.named('SELECT * FROM pet_access WHERE pet_id = @petId ORDER BY created_at ASC'),
      parameters: {'petId': petId},
    );
    accessList = [];
    for (final row in result) {
      accessList.add(await _petAccessRowToJson(row));
    }
  } else {
    final invitedBy = callerCols['invited_by'];
    if (invitedBy != null) {
      final result = await _db.execute(
        Sql.named('SELECT * FROM pet_access WHERE pet_id = @petId AND user_id = @invitedBy'),
        parameters: {'petId': petId, 'invitedBy': invitedBy},
      );
      accessList = [];
      for (final row in result) {
        accessList.add(await _petAccessRowToJson(row));
      }
    } else {
      accessList = [];
    }
  }

  _jsonResponse(request, 200, {'access': accessList, 'caller_role': callerRole});
}

Future<void> _updatePetAccessRole(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final callerId = int.parse(payload['sub'].toString());

  final segments = request.uri.pathSegments;
  final petId = segments[segments.length - 4];
  final targetUserId = int.tryParse(segments[segments.length - 2]);
  if (targetUserId == null) {
    _jsonResponse(request, 400, {'error': 'Invalid user ID'});
    return;
  }

  final callerAccess = await _db.execute(
    Sql.named('SELECT role FROM pet_access WHERE pet_id = @petId AND user_id = @userId'),
    parameters: {'petId': petId, 'userId': callerId},
  );

  if (callerAccess.isEmpty || callerAccess.first.toColumnMap()['role'].toString() != 'guardian') {
    _jsonResponse(request, 403, {'error': 'Only guardians can change roles'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final newRole = body['role'] as String? ?? '';
  if (newRole != 'guardian' && newRole != 'shared') {
    _jsonResponse(request, 400, {'error': 'Role must be guardian or shared'});
    return;
  }

  if (newRole == 'shared' && targetUserId == callerId) {
    final guardianCount = await _db.execute(
      Sql.named('SELECT COUNT(*) as cnt FROM pet_access WHERE pet_id = @petId AND role = \'guardian\''),
      parameters: {'petId': petId},
    );
    final count = guardianCount.first.toColumnMap()['cnt'] as int;
    if (count <= 1) {
      _jsonResponse(request, 400, {'error': 'Cannot demote the last guardian'});
      return;
    }
  }

  final result = await _db.execute(
    Sql.named('UPDATE pet_access SET role = @role WHERE pet_id = @petId AND user_id = @targetUserId RETURNING *'),
    parameters: {'role': newRole, 'petId': petId, 'targetUserId': targetUserId},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User access not found'});
    return;
  }

  _jsonResponse(request, 200, await _petAccessRowToJson(result.first));
}

Future<void> _deletePetAccess(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final callerId = int.parse(payload['sub'].toString());

  final segments = request.uri.pathSegments;
  final petId = segments[segments.length - 3];
  final targetUserId = int.tryParse(segments.last);
  if (targetUserId == null) {
    _jsonResponse(request, 400, {'error': 'Invalid user ID'});
    return;
  }

  final callerAccess = await _db.execute(
    Sql.named('SELECT role FROM pet_access WHERE pet_id = @petId AND user_id = @userId'),
    parameters: {'petId': petId, 'userId': callerId},
  );

  if (callerAccess.isEmpty || callerAccess.first.toColumnMap()['role'].toString() != 'guardian') {
    _jsonResponse(request, 403, {'error': 'Only guardians can remove access'});
    return;
  }

  if (targetUserId == callerId) {
    final guardianCount = await _db.execute(
      Sql.named('SELECT COUNT(*) as cnt FROM pet_access WHERE pet_id = @petId AND role = \'guardian\''),
      parameters: {'petId': petId},
    );
    final count = guardianCount.first.toColumnMap()['cnt'] as int;
    if (count <= 1) {
      _jsonResponse(request, 400, {'error': 'Cannot remove the last guardian'});
      return;
    }
  }

  final result = await _db.execute(
    Sql.named('DELETE FROM pet_access WHERE pet_id = @petId AND user_id = @targetUserId RETURNING id'),
    parameters: {'petId': petId, 'targetUserId': targetUserId},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'User access not found'});
    return;
  }

  _jsonResponse(request, 200, {'deleted': true});
}

// ── Notifications ────────────────────────────────────────────

Future<void> _getNotifications(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  final result = await _db.execute(
    Sql.named('SELECT * FROM notifications WHERE user_id = @userId ORDER BY created_at DESC'),
    parameters: {'userId': userId},
  );

  final notifications = result.map(_notificationRowToMap).toList();
  _jsonResponse(request, 200, notifications);
}

Future<void> _getUnreadCount(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  final result = await _db.execute(
    Sql.named('SELECT COUNT(*) as count FROM notifications WHERE user_id = @userId AND is_read = FALSE'),
    parameters: {'userId': userId},
  );

  final count = result.first.toColumnMap()['count'] as int;
  _jsonResponse(request, 200, {'unread_count': count});
}

Future<void> _markNotificationRead(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  final segments = request.uri.pathSegments;
  final notifId = int.tryParse(segments[segments.length - 2]);
  if (notifId == null) {
    _jsonResponse(request, 400, {'error': 'Invalid notification id'});
    return;
  }

  final result = await _db.execute(
    Sql.named('UPDATE notifications SET is_read = TRUE WHERE id = @id AND user_id = @userId RETURNING *'),
    parameters: {'id': notifId, 'userId': userId},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Notification not found'});
    return;
  }

  _jsonResponse(request, 200, _notificationRowToMap(result.first));
}

Future<void> _markAllNotificationsRead(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  await _db.execute(
    Sql.named('UPDATE notifications SET is_read = TRUE WHERE user_id = @userId AND is_read = FALSE'),
    parameters: {'userId': userId},
  );

  _jsonResponse(request, 200, {'message': 'All notifications marked as read'});
}

Future<void> _getNotificationPreferences(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());
  var result = await _db.execute(
    Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  if (result.isEmpty) {
    await _db.execute(
      Sql.named('INSERT INTO notification_preferences (user_id) VALUES (@userId)'),
      parameters: {'userId': userId},
    );
    result = await _db.execute(
      Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
      parameters: {'userId': userId},
    );
  }

  final row = result.first.toColumnMap();
  final mutedRaw = (row['muted_pet_ids'] as String?) ?? '';
  final mutedList = mutedRaw.isEmpty ? <String>[] : mutedRaw.split(',');
  _jsonResponse(request, 200, {
    'user_id': row['user_id'].toString(),
    'email_reminders_enabled': row['email_reminders_enabled'] as bool,
    'reminder_days_before': row['reminder_days_before'] as int,
    'notify_completed': row['notify_completed'] as bool,
    'muted_pet_ids': mutedList,
  });
}

Future<void> _updateNotificationPreferences(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final userId = int.parse(payload['sub'].toString());
  final emailEnabled = body['email_reminders_enabled'] as bool?;
  final reminderDays = body['reminder_days_before'] as int?;
  final notifyCompleted = body['notify_completed'] as bool?;
  final mutedPetIds = body.containsKey('muted_pet_ids')
      ? (body['muted_pet_ids'] as List<dynamic>?)?.map((e) => e.toString()).join(',') ?? ''
      : null;

  await _db.execute(
    Sql.named('''
      INSERT INTO notification_preferences (user_id, email_reminders_enabled, reminder_days_before, notify_completed, muted_pet_ids, updated_at)
      VALUES (@userId, @emailEnabled, @reminderDays, @notifyCompleted, @mutedPetIds, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        email_reminders_enabled = COALESCE(@emailEnabled, notification_preferences.email_reminders_enabled),
        reminder_days_before = COALESCE(@reminderDays, notification_preferences.reminder_days_before),
        notify_completed = COALESCE(@notifyCompleted, notification_preferences.notify_completed),
        muted_pet_ids = COALESCE(@mutedPetIds, notification_preferences.muted_pet_ids),
        updated_at = NOW()
    '''),
    parameters: {
      'userId': userId,
      'emailEnabled': emailEnabled ?? false,
      'reminderDays': reminderDays ?? 1,
      'notifyCompleted': notifyCompleted ?? true,
      'mutedPetIds': mutedPetIds ?? '',
    },
  );

  final result = await _db.execute(
    Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  final row = result.first.toColumnMap();
  final mutedRaw = (row['muted_pet_ids'] as String?) ?? '';
  final mutedList = mutedRaw.isEmpty ? <String>[] : mutedRaw.split(',');
  _jsonResponse(request, 200, {
    'user_id': row['user_id'].toString(),
    'email_reminders_enabled': row['email_reminders_enabled'] as bool,
    'reminder_days_before': row['reminder_days_before'] as int,
    'notify_completed': row['notify_completed'] as bool,
    'muted_pet_ids': mutedList,
  });
}

Future<void> _checkDueNotifications(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }

  final userId = int.parse(payload['sub'].toString());

  Map<String, String> petNames = {};
  try {
    final body = await _readJson(request);
    if (body != null && body['pet_names'] is Map) {
      final raw = body['pet_names'] as Map;
      petNames = raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  } catch (_) {}

  var prefResult = await _db.execute(
    Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  int reminderDays = 1;
  bool emailEnabled = false;
  if (prefResult.isNotEmpty) {
    final prefRow = prefResult.first.toColumnMap();
    reminderDays = prefRow['reminder_days_before'] as int;
    emailEnabled = prefRow['email_reminders_enabled'] as bool;
  }

  final dueEntries = await _db.execute(
    Sql.named('''
      SELECT he.* FROM health_entries he
      WHERE he.next_due_date <= NOW() + make_interval(days => @reminderDays)
      AND he.next_due_date IS NOT NULL
    '''),
    parameters: {'reminderDays': reminderDays},
  );

  int created = 0;
  String? userEmail;

  if (emailEnabled) {
    final userResult = await _db.execute(
      Sql.named('SELECT email FROM users WHERE id = @userId'),
      parameters: {'userId': userId},
    );
    if (userResult.isNotEmpty) {
      userEmail = userResult.first.toColumnMap()['email'].toString();
    }
  }

  for (final entry in dueEntries) {
    final cols = entry.toColumnMap();
    final entryId = cols['id'].toString();
    final petId = cols['pet_id'].toString();
    final entryName = cols['name'].toString();
    final entryType = cols['type'].toString();
    final nextDue = cols['next_due_date'].toString();

    final existing = await _db.execute(
      Sql.named('''
        SELECT id FROM notifications
        WHERE user_id = @userId AND health_entry_id = @entryId
        AND created_at > NOW() - INTERVAL '1 day'
      '''),
      parameters: {'userId': userId, 'entryId': entryId},
    );

    if (existing.isNotEmpty) continue;

    final petName = petNames[petId] ?? '';
    final petPrefix = petName.isNotEmpty ? '$petName - ' : '';
    final isOverdue = DateTime.tryParse(nextDue)?.isBefore(DateTime.now()) ?? false;
    final title = isOverdue
        ? '${petPrefix}Overdue: $entryName'
        : '${petPrefix}Upcoming: $entryName';
    final message = isOverdue
        ? '$entryName ($entryType) was due on $nextDue'
        : '$entryName ($entryType) is due on $nextDue';

    await _db.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, health_entry_id, title, message, type)
        VALUES (@userId, @petId, @entryId, @title, @message, @type)
      '''),
      parameters: {
        'userId': userId,
        'petId': petId,
        'entryId': entryId,
        'title': title,
        'message': message,
        'type': isOverdue ? 'overdue' : 'reminder',
      },
    );
    created++;

    if (emailEnabled && userEmail != null) {
      await _sendEmailReminder(userEmail, title, message);
    }
  }

  _jsonResponse(request, 200, {
    'message': 'Check complete',
    'notifications_created': created,
  });
}

Future<void> _sendEmailReminder(String toEmail, String subject, String body) async {
  // TODO: Implement actual email sending via SendGrid or similar service.
  // Requires SENDGRID_API_KEY environment variable.
  // For now, log the email that would be sent.
  print('[EMAIL STUB] To: $toEmail | Subject: $subject | Body: $body');
}

// ── Health Issues ─────────────────────────────────────────────

Map<String, dynamic> _healthIssueToMap(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'pet_id': cols['pet_id'].toString(),
    'title': cols['title'].toString(),
    'description': (cols['description'] ?? '').toString(),
    'start_date': cols['start_date']?.toString(),
    'end_date': cols['end_date']?.toString(),
    'created_at': cols['created_at'].toString(),
    'updated_at': cols['updated_at'].toString(),
  };
}

Future<void> _getHealthIssues(HttpRequest request) async {
  final petId = request.uri.queryParameters['pet_id'];
  if (petId == null || petId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'pet_id is required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('SELECT * FROM health_issues WHERE pet_id = @petId ORDER BY created_at DESC'),
    parameters: {'petId': petId},
  );

  final issues = <Map<String, dynamic>>[];
  for (final row in result) {
    final issue = _healthIssueToMap(row);
    final issueId = int.tryParse(issue['id'].toString()) ?? 0;
    final eventsResult = await _db.execute(
      Sql.named('SELECT health_entry_id FROM health_issue_events WHERE health_issue_id = @issueId'),
      parameters: {'issueId': issueId},
    );
    issue['event_ids'] = eventsResult.map((r) => r.toColumnMap()['health_entry_id'].toString()).toList();
    issues.add(issue);
  }

  _jsonResponse(request, 200, issues);
}

Future<void> _createHealthIssue(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final petId = body['pet_id'] as String? ?? '';
  final title = body['title'] as String? ?? '';
  final description = body['description'] as String? ?? '';
  final startDate = body['start_date'] as String?;
  final endDate = body['end_date'] as String?;

  if (petId.isEmpty || title.isEmpty) {
    _jsonResponse(request, 400, {'error': 'pet_id and title are required'});
    return;
  }

  final result = await _db.execute(
    Sql.named('''
      INSERT INTO health_issues (pet_id, title, description, start_date, end_date)
      VALUES (@petId, @title, @description, ${startDate != null ? '@startDate::date' : 'NULL'}, ${endDate != null ? '@endDate::date' : 'NULL'})
      RETURNING *
    '''),
    parameters: {
      'petId': petId,
      'title': title,
      'description': description,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    },
  );

  final issue = _healthIssueToMap(result.first);
  issue['event_ids'] = <String>[];
  _jsonResponse(request, 201, issue);
}

Future<void> _updateHealthIssue(HttpRequest request) async {
  final id = int.tryParse(request.uri.pathSegments.last);
  if (id == null) {
    _jsonResponse(request, 400, {'error': 'Invalid issue ID'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _db.execute(
    Sql.named('SELECT * FROM health_issues WHERE id = @id'),
    parameters: {'id': id},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Health issue not found'});
    return;
  }

  final row = _healthIssueToMap(existing.first);

  final hasStartDate = body.containsKey('start_date');
  final hasEndDate = body.containsKey('end_date');
  final newStartDate = hasStartDate ? body['start_date'] as String? : (row['start_date'] as String?);
  final newEndDate = hasEndDate ? body['end_date'] as String? : (row['end_date'] as String?);

  final result = await _db.execute(
    Sql.named('''
      UPDATE health_issues SET
        title = @title, description = @description,
        start_date = ${newStartDate != null ? '@startDate::date' : 'NULL'},
        end_date = ${newEndDate != null ? '@endDate::date' : 'NULL'},
        updated_at = NOW()
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'id': id,
      'title': body['title'] ?? row['title'],
      'description': body['description'] ?? row['description'],
      if (newStartDate != null) 'startDate': newStartDate,
      if (newEndDate != null) 'endDate': newEndDate,
    },
  );

  final issue = _healthIssueToMap(result.first);
  final eventsResult = await _db.execute(
    Sql.named('SELECT health_entry_id FROM health_issue_events WHERE health_issue_id = @issueId'),
    parameters: {'issueId': id},
  );
  issue['event_ids'] = eventsResult.map((r) => r.toColumnMap()['health_entry_id'].toString()).toList();
  _jsonResponse(request, 200, issue);
}

Future<void> _deleteHealthIssue(HttpRequest request) async {
  final id = int.tryParse(request.uri.pathSegments.last);
  if (id == null) {
    _jsonResponse(request, 400, {'error': 'Invalid issue ID'});
    return;
  }

  final result = await _db.execute(
    Sql.named('DELETE FROM health_issues WHERE id = @id RETURNING id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Health issue not found'});
    return;
  }

  await _db.execute(
    Sql.named('UPDATE health_entries SET health_issue_id = NULL WHERE health_issue_id = @id'),
    parameters: {'id': id},
  );

  _jsonResponse(request, 200, {'deleted': true});
}

Future<void> _linkHealthIssueEvent(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final issueId = int.tryParse(segments[segments.length - 2]);
  if (issueId == null) {
    _jsonResponse(request, 400, {'error': 'Invalid issue ID'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final entryId = body['health_entry_id']?.toString();
  if (entryId == null || entryId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'health_entry_id is required'});
    return;
  }

  final issueExists = await _db.execute(
    Sql.named('SELECT id FROM health_issues WHERE id = @id'),
    parameters: {'id': issueId},
  );
  if (issueExists.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Health issue not found'});
    return;
  }

  await _db.execute(
    Sql.named('INSERT INTO health_issue_events (health_issue_id, health_entry_id) VALUES (@issueId, @entryId::uuid) ON CONFLICT DO NOTHING'),
    parameters: {'issueId': issueId, 'entryId': entryId},
  );

  await _db.execute(
    Sql.named('UPDATE health_entries SET health_issue_id = @issueId WHERE id = @entryId::uuid'),
    parameters: {'issueId': issueId, 'entryId': entryId},
  );

  _jsonResponse(request, 200, {'linked': true});
}

Future<void> _unlinkHealthIssueEvent(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final issueId = int.tryParse(segments[segments.length - 3]);
  final entryId = segments.last;
  if (issueId == null || entryId.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Invalid issue or entry ID'});
    return;
  }

  await _db.execute(
    Sql.named('DELETE FROM health_issue_events WHERE health_issue_id = @issueId AND health_entry_id = @entryId::uuid'),
    parameters: {'issueId': issueId, 'entryId': entryId},
  );

  await _db.execute(
    Sql.named('UPDATE health_entries SET health_issue_id = NULL WHERE id = @entryId::uuid AND health_issue_id = @issueId'),
    parameters: {'entryId': entryId, 'issueId': issueId},
  );

  _jsonResponse(request, 200, {'unlinked': true});
}

Map<String, dynamic> _notificationRowToMap(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'user_id': cols['user_id'].toString(),
    'pet_id': cols['pet_id']?.toString() ?? '',
    'health_entry_id': cols['health_entry_id']?.toString() ?? '',
    'title': cols['title'].toString(),
    'message': cols['message'].toString(),
    'type': cols['type'].toString(),
    'is_read': cols['is_read'] as bool,
    'created_at': cols['created_at'].toString(),
  };
}

// ── Helpers ──────────────────────────────────────────────────

Map<String, dynamic> _weightRowToMap(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'pet_id': cols['pet_id'].toString(),
    'date': cols['date'].toString(),
    'weight': cols['weight'],
    'notes': (cols['notes'] ?? '').toString(),
    'created_at': cols['created_at'].toString(),
  };
}

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
    'repeat_end_date': cols['repeat_end_date']?.toString(),
    'start_date': cols['start_date'].toString(),
    'next_due_date': cols['next_due_date'].toString(),
    'notes': cols['notes'].toString(),
    'health_issue_id': cols['health_issue_id']?.toString(),
    'health_issue_title': cols.containsKey('health_issue_title') ? cols['health_issue_title']?.toString() : null,
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
