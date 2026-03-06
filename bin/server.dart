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

late Pool _pool;
late String _jwtSecret;
const _accessTokenExpiry = Duration(minutes: 30);
const _refreshTokenExpiry = Duration(days: 30);

String _t(String locale, String key, [Map<String, String>? params]) {
  final lang = _translations[locale] ?? _translations['en']!;
  var text = lang[key] ?? _translations['en']![key] ?? key;
  if (params != null) {
    params.forEach((k, v) {
      text = text.replaceAll('{$k}', v);
    });
  }
  return text;
}

const _translations = {
  'en': {
    'completed_title': '{pet}{name} completed',
    'completed_message': '{name} has been completed',
    'overdue_title': '{pet}Overdue: {name}',
    'overdue_message': '{name} was due on {date} and has not been marked as done',
    'reminder_title': '{pet}Due soon: {name}',
    'reminder_message': '{name} is due on {date}',
    'memorial_title': 'In loving memory of {name}',
    'memorial_message': 'We are deeply sorry to let you know that {name} has crossed the rainbow bridge. Their profile will be kept as an archive in their guardian\'s account.',
    'event_created': '{pet}New event: {name}',
    'event_created_msg': 'A new health event "{name}" has been added',
    'event_updated': '{pet}Event updated: {name}',
    'event_updated_msg': 'The health event "{name}" has been updated',
    'event_deleted': '{pet}Event removed: {name}',
    'event_deleted_msg': 'The health event "{name}" has been removed',
    'issue_created': '{pet}New issue: {name}',
    'issue_created_msg': 'A new health issue "{name}" has been added',
    'issue_updated': '{pet}Issue updated: {name}',
    'issue_updated_msg': 'The health issue "{name}" has been updated',
    'issue_deleted': '{pet}Issue removed: {name}',
    'issue_deleted_msg': 'The health issue "{name}" has been removed',
    'share_granted': 'Access granted to {pet}',
    'share_granted_msg': 'You have been given access to {pet}',
    'share_revoked': 'Access revoked for {pet}',
    'share_revoked_msg': 'Your access to {pet} has been revoked',
    'org_pet_transferred_out': '{pet} has been transferred',
    'org_pet_transferred_out_msg': '{pet} has been transferred to {recipient}',
    'org_pet_received': 'You received {pet}',
    'org_pet_received_msg': '{pet} has been transferred to you from {org}',
    'org_member_joined': 'New member in {org}',
    'org_member_joined_msg': '{member} has joined {org}',
    'org_member_left': 'Member left {org}',
    'org_member_left_msg': '{member} has left {org}',
    'org_pet_donated': '{pet} transferred to {org}',
    'org_pet_donated_msg': '{pet} has been transferred to organization {org}',
    'org_invite_received': 'Invitation to join {org}',
    'org_invite_received_msg': 'You have been invited to join {org} as {role}',
    'org_invite_accepted': '{member} accepted your invitation',
    'org_invite_accepted_msg': '{member} has accepted the invitation to join {org}',
    'org_invite_declined': '{member} declined your invitation',
    'org_invite_declined_msg': '{member} has declined the invitation to join {org}',
  },
  'fr': {
    'completed_title': '{pet}{name} terminé',
    'completed_message': '{name} a été terminé',
    'overdue_title': '{pet}En retard : {name}',
    'overdue_message': '{name} était prévu le {date} et n\'a pas été marqué comme fait',
    'reminder_title': '{pet}Bientôt dû : {name}',
    'reminder_message': '{name} est prévu le {date}',
    'memorial_title': 'En mémoire de {name}',
    'memorial_message': 'Nous sommes profondément désolés de vous informer que {name} a traversé le pont de l\'arc-en-ciel. Son profil sera conservé comme archive dans le compte de son gardien.',
    'event_created': '{pet}Nouvel événement : {name}',
    'event_created_msg': 'Un nouvel événement santé « {name} » a été ajouté',
    'event_updated': '{pet}Événement mis à jour : {name}',
    'event_updated_msg': 'L\'événement santé « {name} » a été mis à jour',
    'event_deleted': '{pet}Événement supprimé : {name}',
    'event_deleted_msg': 'L\'événement santé « {name} » a été supprimé',
    'issue_created': '{pet}Nouveau problème : {name}',
    'issue_created_msg': 'Un nouveau problème de santé « {name} » a été ajouté',
    'issue_updated': '{pet}Problème mis à jour : {name}',
    'issue_updated_msg': 'Le problème de santé « {name} » a été mis à jour',
    'issue_deleted': '{pet}Problème supprimé : {name}',
    'issue_deleted_msg': 'Le problème de santé « {name} » a été supprimé',
    'share_granted': 'Accès accordé à {pet}',
    'share_granted_msg': 'Vous avez reçu l\'accès à {pet}',
    'share_revoked': 'Accès révoqué pour {pet}',
    'share_revoked_msg': 'Votre accès à {pet} a été révoqué',
    'org_pet_transferred_out': '{pet} a été transféré',
    'org_pet_transferred_out_msg': '{pet} a été transféré à {recipient}',
    'org_pet_received': 'Vous avez reçu {pet}',
    'org_pet_received_msg': '{pet} vous a été transféré depuis {org}',
    'org_member_joined': 'Nouveau membre dans {org}',
    'org_member_joined_msg': '{member} a rejoint {org}',
    'org_member_left': 'Membre parti de {org}',
    'org_member_left_msg': '{member} a quitté {org}',
    'org_pet_donated': '{pet} transféré à {org}',
    'org_pet_donated_msg': '{pet} a été transféré à l\'organisation {org}',
    'org_invite_received': 'Invitation à rejoindre {org}',
    'org_invite_received_msg': 'Vous avez été invité(e) à rejoindre {org} en tant que {role}',
    'org_invite_accepted': '{member} a accepté votre invitation',
    'org_invite_accepted_msg': '{member} a accepté l\'invitation à rejoindre {org}',
    'org_invite_declined': '{member} a refusé votre invitation',
    'org_invite_declined_msg': '{member} a refusé l\'invitation à rejoindre {org}',
  },
};

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

  final needsSsl = dbUrl.contains('neon.tech') || dbUrl.contains('sslmode=require');
  final sslMode = needsSsl ? SslMode.require : SslMode.disable;

  _pool = Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(
      maxConnectionCount: 5,
      sslMode: sslMode,
    ),
  );
  print('Connected to PostgreSQL (pool, ssl=$needsSsl)');

  await _pool.execute(Sql('''
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

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email VARCHAR(255) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      name VARCHAR(255) NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));

  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN first_name VARCHAR(100) DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN last_name VARCHAR(100) DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN category VARCHAR(50) DEFAULT 'pet_guardian';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN bio TEXT DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN photo_url TEXT DEFAULT '';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE users ADD COLUMN locale VARCHAR(10) DEFAULT 'en';
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('users table ready');

  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE shared_pets ADD COLUMN user_id INTEGER DEFAULT NULL;
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('shared_pets user_id column ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS refresh_tokens (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token VARCHAR(255) UNIQUE NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('refresh_tokens table ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS password_reset_tokens (
      id SERIAL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      code VARCHAR(6) NOT NULL,
      expires_at TIMESTAMPTZ NOT NULL,
      used BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('password_reset_tokens table ready');

  await _pool.execute(Sql('''
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

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS notification_preferences (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      email_reminders_enabled BOOLEAN NOT NULL DEFAULT FALSE,
      reminder_days_before INTEGER NOT NULL DEFAULT 1,
      notify_completed BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  await _pool.execute(Sql('''
    ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS notify_completed BOOLEAN NOT NULL DEFAULT TRUE
  '''));
  await _pool.execute(Sql('''
    ALTER TABLE notification_preferences ADD COLUMN IF NOT EXISTS muted_pet_ids TEXT NOT NULL DEFAULT ''
  '''));
  print('notification_preferences table ready');

  await _pool.execute(Sql('''
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

  await _pool.execute(Sql('''
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

  await _pool.execute(Sql('''
    ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS repeat_end_date DATE
  '''));

  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS frequency_interval INT DEFAULT 1;
      ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_frequency_check;
      ALTER TABLE health_entries ADD CONSTRAINT health_entries_frequency_check
        CHECK (frequency = ANY (ARRAY['once','daily','weekly','monthly','yearly','custom']));
      UPDATE health_entries SET type = 'vet_visit' WHERE type = 'vaccine';
      ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_type_check;
      ALTER TABLE health_entries ADD CONSTRAINT health_entries_type_check
        CHECK (type = ANY (ARRAY['medication','preventive','vet_visit','procedure']));
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  await _pool.execute(Sql('''
    ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS remind_days_before INTEGER NOT NULL DEFAULT 1
  '''));
  print('health_entries schema updated');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS health_event_photos (
      id SERIAL PRIMARY KEY,
      event_id VARCHAR(255) NOT NULL,
      photo_path TEXT NOT NULL,
      caption TEXT DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('health_event_photos table ready');

  await _pool.execute(Sql('''
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

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS health_issue_events (
      health_issue_id INT NOT NULL REFERENCES health_issues(id) ON DELETE CASCADE,
      health_entry_id UUID NOT NULL,
      PRIMARY KEY (health_issue_id, health_entry_id)
    )
  '''));

  await _pool.execute(Sql('''
    ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS health_issue_id INT REFERENCES health_issues(id) ON DELETE SET NULL
  '''));

  await _pool.execute(Sql('ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS start_date DATE'));
  await _pool.execute(Sql('ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS end_date DATE'));

  print('health_issues tables ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS pets (
      id VARCHAR(255) PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      species VARCHAR(100) NOT NULL,
      breed VARCHAR(255) DEFAULT '',
      age DOUBLE PRECISION,
      date_of_birth DATE,
      weight DOUBLE PRECISION,
      gender VARCHAR(50),
      bio TEXT DEFAULT '',
      insurance TEXT DEFAULT '',
      neutered_date DATE,
      neuter_dismissed BOOLEAN DEFAULT FALSE,
      chip_id VARCHAR(255) DEFAULT '',
      chip_dismissed BOOLEAN DEFAULT FALSE,
      photo_path TEXT,
      vet_id VARCHAR(255),
      color_value BIGINT,
      passed_away BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  await _pool.execute(Sql('ALTER TABLE pets ADD COLUMN IF NOT EXISTS date_of_birth DATE'));
  await _pool.execute(Sql('ALTER TABLE pets ALTER COLUMN color_value TYPE BIGINT'));
  print('pets table ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS organizations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      type VARCHAR(50) NOT NULL DEFAULT 'professional',
      email VARCHAR(255) DEFAULT '',
      phone VARCHAR(100) DEFAULT '',
      address TEXT DEFAULT '',
      website VARCHAR(255) DEFAULT '',
      bio TEXT DEFAULT '',
      photo_url TEXT DEFAULT '',
      created_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('organizations table ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS organization_users (
      id SERIAL PRIMARY KEY,
      organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      role VARCHAR(20) NOT NULL DEFAULT 'member',
      invited_by INTEGER REFERENCES users(id),
      invite_code VARCHAR(20) UNIQUE,
      invite_expires_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(organization_id, user_id)
    )
  '''));
  print('organization_users table ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS archived_pets (
      id SERIAL PRIMARY KEY,
      organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
      user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      pet_id VARCHAR(255) NOT NULL,
      pet_name VARCHAR(255) NOT NULL DEFAULT '',
      species VARCHAR(100) NOT NULL DEFAULT '',
      pdf_data TEXT DEFAULT '',
      transfer_type VARCHAR(50) NOT NULL DEFAULT 'other',
      transferred_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      transferred_to_org_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
      notes TEXT DEFAULT '',
      archived_at TIMESTAMPTZ DEFAULT NOW(),
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('archived_pets table ready');

  await _pool.execute(Sql('''
    DO \$\$ BEGIN
      ALTER TABLE pets ADD COLUMN organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL;
    EXCEPTION WHEN OTHERS THEN NULL;
    END \$\$;
  '''));
  print('pets organization_id column ready');

  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS family_events (
      id SERIAL PRIMARY KEY,
      pet_id VARCHAR(255) NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
      organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
      assigned_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      from_date DATE NOT NULL,
      to_date DATE,
      notes TEXT DEFAULT '',
      created_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
  print('family_events table ready');

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

int? _getUserIdFromRequest(HttpRequest request) {
  final authHeader = request.headers.value('authorization');
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring(7);
  final payload = _verifyAccessToken(token);
  if (payload == null) return null;
  final sub = payload['sub'];
  if (sub == null) return null;
  return int.tryParse(sub.toString());
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
  } else if (path == '/api/auth/forgot-password' && method == 'POST') {
    await _authForgotPassword(request);
  } else if (path == '/api/auth/reset-password' && method == 'POST') {
    await _authResetPassword(request);
  }
  // Pets CRUD
  else if (path == '/api/pets/all' && method == 'GET') {
    await _getAllPetsIncludingOrg(request);
  } else if (path == '/api/pets' && method == 'GET') {
    await _getPets(request);
  } else if (path == '/api/pets' && method == 'POST') {
    await _createPet(request);
  } else if (RegExp(r'^/api/pets/[^/]+$').hasMatch(path) && method == 'PUT') {
    await _updatePet(request);
  } else if (RegExp(r'^/api/pets/[^/]+$').hasMatch(path) && method == 'DELETE') {
    await _deletePetRecord(request);
  }
  // Health entries
  else if (path == '/api/health-entries' && method == 'GET') {
    await _getHealthEntries(request);
  } else if (path == '/api/health-entries' && method == 'POST') {
    await _createHealthEntry(request);
  } else if (path == '/api/health-entries/export' && method == 'GET') {
    await _exportCsv(request);
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
  } else if (RegExp(r'^/api/health-entries/[^/]+/undo-complete$')
          .hasMatch(path) &&
      method == 'POST') {
    await _undoComplete(request);
  } else if (RegExp(r'^/api/health-entries/[^/]+/history$').hasMatch(path) &&
      method == 'GET') {
    await _getHistory(request);
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
  // Pet passed away
  else if (RegExp(r'^/api/pets/[^/]+/passed-away$').hasMatch(path) && method == 'POST') {
    await _markPetPassedAway(request);
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
  } else if (RegExp(r'^/api/premium/[^/]+$').hasMatch(path) && method == 'GET') {
    await _getPremiumStatus(request);
  }
  // Organizations
  else if (path == '/api/organizations' && method == 'GET') {
    await _getOrganizations(request);
  } else if (path == '/api/organizations' && method == 'POST') {
    await _createOrganization(request);
  } else if (RegExp(r'^/api/organizations/join/[^/]+$').hasMatch(path) && method == 'POST') {
    await _joinOrganization(request);
  } else if (RegExp(r'^/api/organizations/\d+/photo$').hasMatch(path) && method == 'POST') {
    await _uploadOrgPhoto(request);
  } else if (RegExp(r'^/api/organizations/\d+/members/me$').hasMatch(path) && method == 'DELETE') {
    await _leaveOrganization(request);
  } else if (RegExp(r'^/api/organizations/\d+/members/\d+/role$').hasMatch(path) && method == 'PUT') {
    await _updateOrgMemberRole(request);
  } else if (RegExp(r'^/api/organizations/\d+/members/\d+$').hasMatch(path) && method == 'DELETE') {
    await _removeOrgMember(request);
  } else if (RegExp(r'^/api/organizations/\d+/members$').hasMatch(path) && method == 'GET') {
    await _getOrgMembers(request);
  } else if (path == '/api/organizations/invites/pending' && method == 'GET') {
    await _getPendingOrgInvites(request);
  } else if (RegExp(r'^/api/organizations/invites/\d+/accept$').hasMatch(path) && method == 'POST') {
    await _acceptOrgInvite(request);
  } else if (RegExp(r'^/api/organizations/invites/\d+/decline$').hasMatch(path) && method == 'POST') {
    await _declineOrgInvite(request);
  } else if (RegExp(r'^/api/organizations/\d+/invite$').hasMatch(path) && method == 'POST') {
    await _createOrgInvite(request);
  } else if (RegExp(r'^/api/organizations/\d+/pets/[^/]+/transfer$').hasMatch(path) && method == 'POST') {
    await _transferOrgPet(request);
  } else if (RegExp(r'^/api/organizations/\d+/pets$').hasMatch(path) && method == 'GET') {
    await _getOrgPets(request);
  } else if (RegExp(r'^/api/organizations/\d+/pets$').hasMatch(path) && method == 'POST') {
    await _createOrgPet(request);
  } else if (RegExp(r'^/api/organizations/\d+/archived$').hasMatch(path) && method == 'GET') {
    await _getOrgArchivedPets(request);
  } else if (RegExp(r'^/api/organizations/\d+$').hasMatch(path) && method == 'GET') {
    await _getOrganization(request);
  } else if (RegExp(r'^/api/organizations/\d+$').hasMatch(path) && method == 'PUT') {
    await _updateOrganization(request);
  } else if (RegExp(r'^/api/organizations/\d+$').hasMatch(path) && method == 'DELETE') {
    await _deleteOrganization(request);
  }
  // Pet transfer to org (individual -> org)
  else if (RegExp(r'^/api/pets/[^/]+/transfer-to-org$').hasMatch(path) && method == 'POST') {
    await _transferPetToOrg(request);
  }
  // Family events
  else if (RegExp(r'^/api/pets/[^/]+/family-events$').hasMatch(path) && method == 'GET') {
    await _getFamilyEvents(request);
  } else if (RegExp(r'^/api/pets/[^/]+/family-events$').hasMatch(path) && method == 'POST') {
    await _createFamilyEvent(request);
  } else if (RegExp(r'^/api/pets/[^/]+/family-events/\d+$').hasMatch(path) && method == 'PUT') {
    await _updateFamilyEvent(request);
  } else if (RegExp(r'^/api/pets/[^/]+/family-events/\d+$').hasMatch(path) && method == 'DELETE') {
    await _deleteFamilyEvent(request);
  }
  // User's personal archived pets
  else if (path == '/api/archived-pets' && method == 'GET') {
    await _getUserArchivedPets(request);
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
    'locale': (cols['locale'] ?? 'en').toString(),
    'created_at': cols['created_at'].toString(),
    'updated_at': cols['updated_at'].toString(),
  };
}

Future<String> _getUserLocale(int userId) async {
  final r = await _pool.execute(
    Sql.named('SELECT locale FROM users WHERE id = @id'),
    parameters: {'id': userId},
  );
  if (r.isEmpty) return 'en';
  return (r.first.toColumnMap()['locale'] ?? 'en').toString();
}

// ── Pet CRUD handlers ────────────────────────────────────────

Map<String, dynamic> _petRowToJson(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'user_id': cols['user_id'].toString(),
    'name': (cols['name'] ?? '').toString(),
    'species': (cols['species'] ?? '').toString(),
    'breed': (cols['breed'] ?? '').toString(),
    'age': cols['age'],
    'dateOfBirth': cols['date_of_birth']?.toString(),
    'date_of_birth': cols['date_of_birth']?.toString(),
    'weight': cols['weight'],
    'gender': cols['gender']?.toString(),
    'bio': (cols['bio'] ?? '').toString(),
    'insurance': (cols['insurance'] ?? '').toString(),
    'neuteredDate': cols['neutered_date']?.toString(),
    'neuterDismissed': cols['neuter_dismissed'] == true,
    'chipId': (cols['chip_id'] ?? '').toString(),
    'chipDismissed': cols['chip_dismissed'] == true,
    'photoPath': cols['photo_path']?.toString(),
    'vetId': cols['vet_id']?.toString(),
    'colorValue': cols['color_value'],
    'passedAway': cols['passed_away'] == true,
    'organization_id': cols['organization_id']?.toString(),
    'created_at': cols['created_at']?.toString(),
    'updated_at': cols['updated_at']?.toString(),
  };
}

Future<void> _getPets(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final result = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE user_id = @userId AND organization_id IS NULL ORDER BY created_at'),
    parameters: {'userId': userId},
  );
  final pets = result.map(_petRowToJson).toList();
  _jsonResponse(request, 200, pets);
}

Future<void> _getAllPetsIncludingOrg(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final personalResult = await _pool.execute(
    Sql.named('SELECT p.*, NULL::text AS organization_name FROM pets p WHERE p.user_id = @userId AND p.organization_id IS NULL ORDER BY p.created_at'),
    parameters: {'userId': userId},
  );

  final orgResult = await _pool.execute(
    Sql.named('''
      SELECT p.*, o.name AS organization_name
      FROM pets p
      INNER JOIN organizations o ON p.organization_id = o.id
      INNER JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = @userId
      ORDER BY o.name, p.created_at
    '''),
    parameters: {'userId': userId},
  );

  final allPets = <Map<String, dynamic>>[];
  for (final row in personalResult) {
    final pet = _petRowToJson(row);
    pet['organization_name'] = null;
    allPets.add(pet);
  }
  for (final row in orgResult) {
    final pet = _petRowToJson(row);
    pet['organization_name'] = row.toColumnMap()['organization_name']?.toString();
    allPets.add(pet);
  }
  _jsonResponse(request, 200, allPets);
}

Future<void> _createPet(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final id = body['id'] as String? ?? '';
  final name = body['name'] as String? ?? '';
  final species = body['species'] as String? ?? '';

  if (id.isEmpty || name.isEmpty || species.isEmpty) {
    _jsonResponse(request, 400, {'error': 'id, name, and species are required'});
    return;
  }

  final existing = await _pool.execute(
    Sql.named('SELECT id FROM pets WHERE id = @id'),
    parameters: {'id': id},
  );
  if (existing.isNotEmpty) {
    await _pool.execute(
      Sql.named('''
        UPDATE pets SET user_id = @userId, name = @name, species = @species,
          breed = @breed,
          date_of_birth = ${body['dateOfBirth'] != null ? '@dateOfBirth::date' : 'NULL'},
          weight = ${body['weight'] != null ? '@weight' : 'NULL'},
          gender = ${body['gender'] != null ? '@gender' : 'NULL'},
          bio = @bio, insurance = @insurance,
          neutered_date = ${body['neuteredDate'] != null ? '@neuteredDate::date' : 'NULL'},
          neuter_dismissed = @neuterDismissed,
          chip_id = @chipId, chip_dismissed = @chipDismissed,
          photo_path = ${body['photoPath'] != null ? '@photoPath' : 'NULL'},
          vet_id = ${body['vetId'] != null ? '@vetId' : 'NULL'},
          color_value = ${body['colorValue'] != null ? '@colorValue' : 'NULL'},
          passed_away = @passedAway,
          updated_at = NOW()
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'userId': userId,
        'name': name,
        'species': species,
        'breed': (body['breed'] ?? '').toString(),
        if (body['dateOfBirth'] != null) 'dateOfBirth': body['dateOfBirth'].toString(),
        if (body['weight'] != null) 'weight': (body['weight'] as num).toDouble(),
        if (body['gender'] != null) 'gender': body['gender'].toString(),
        'bio': (body['bio'] ?? '').toString(),
        'insurance': (body['insurance'] ?? '').toString(),
        if (body['neuteredDate'] != null) 'neuteredDate': body['neuteredDate'].toString(),
        'neuterDismissed': body['neuterDismissed'] == true,
        'chipId': (body['chipId'] ?? '').toString(),
        'chipDismissed': body['chipDismissed'] == true,
        if (body['photoPath'] != null) 'photoPath': body['photoPath'].toString(),
        if (body['vetId'] != null) 'vetId': body['vetId'].toString(),
        if (body['colorValue'] != null) 'colorValue': body['colorValue'] as int,
        'passedAway': body['passedAway'] == true,
      },
    );
    final updated = await _pool.execute(
      Sql.named('SELECT * FROM pets WHERE id = @id'),
      parameters: {'id': id},
    );
    _jsonResponse(request, 200, _petRowToJson(updated.first));
    return;
  }

  final orgId = body['organization_id'] != null ? int.tryParse(body['organization_id'].toString()) : null;
  await _pool.execute(
    Sql.named('''
      INSERT INTO pets (id, user_id, name, species, breed, date_of_birth, weight, gender, bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed, photo_path, vet_id, color_value, passed_away, organization_id)
      VALUES (@id, @userId, @name, @species, @breed, ${body['dateOfBirth'] != null ? '@dateOfBirth::date' : 'NULL'}, ${body['weight'] != null ? '@weight' : 'NULL'}, ${body['gender'] != null ? '@gender' : 'NULL'}, @bio, @insurance, ${body['neuteredDate'] != null ? '@neuteredDate::date' : 'NULL'}, @neuterDismissed, @chipId, @chipDismissed, ${body['photoPath'] != null ? '@photoPath' : 'NULL'}, ${body['vetId'] != null ? '@vetId' : 'NULL'}, ${body['colorValue'] != null ? '@colorValue' : 'NULL'}, @passedAway, ${orgId != null ? '@orgId' : 'NULL'})
    '''),
    parameters: {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'breed': (body['breed'] ?? '').toString(),
      if (body['dateOfBirth'] != null) 'dateOfBirth': body['dateOfBirth'].toString(),
      if (body['weight'] != null) 'weight': (body['weight'] as num).toDouble(),
      if (body['gender'] != null) 'gender': body['gender'].toString(),
      'bio': (body['bio'] ?? '').toString(),
      'insurance': (body['insurance'] ?? '').toString(),
      if (body['neuteredDate'] != null) 'neuteredDate': body['neuteredDate'].toString(),
      'neuterDismissed': body['neuterDismissed'] == true,
      'chipId': (body['chipId'] ?? '').toString(),
      'chipDismissed': body['chipDismissed'] == true,
      if (body['photoPath'] != null) 'photoPath': body['photoPath'].toString(),
      if (body['vetId'] != null) 'vetId': body['vetId'].toString(),
      if (body['colorValue'] != null) 'colorValue': body['colorValue'] as int,
      'passedAway': body['passedAway'] == true,
      if (orgId != null) 'orgId': orgId,
    },
  );

  final created = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE id = @id'),
    parameters: {'id': id},
  );
  _jsonResponse(request, 201, _petRowToJson(created.first));
}

Future<void> _updatePet(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final petId = request.uri.pathSegments.last;
  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE id = @id AND user_id = @userId'),
    parameters: {'id': petId, 'userId': userId},
  );
  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Pet not found'});
    return;
  }

  await _pool.execute(
    Sql.named('''
      UPDATE pets SET
        name = @name, species = @species, breed = @breed,
        date_of_birth = ${body['dateOfBirth'] != null ? '@dateOfBirth::date' : 'NULL'},
        weight = ${body['weight'] != null ? '@weight' : 'NULL'},
        gender = ${body['gender'] != null ? '@gender' : 'NULL'},
        bio = @bio, insurance = @insurance,
        neutered_date = ${body['neuteredDate'] != null ? '@neuteredDate::date' : 'NULL'},
        neuter_dismissed = @neuterDismissed,
        chip_id = @chipId, chip_dismissed = @chipDismissed,
        photo_path = ${body['photoPath'] != null ? '@photoPath' : 'NULL'},
        vet_id = ${body['vetId'] != null ? '@vetId' : 'NULL'},
        color_value = ${body['colorValue'] != null ? '@colorValue' : 'NULL'},
        passed_away = @passedAway,
        updated_at = NOW()
      WHERE id = @id AND user_id = @userId
      RETURNING *
    '''),
    parameters: {
      'id': petId,
      'userId': userId,
      'name': (body['name'] ?? '').toString(),
      'species': (body['species'] ?? '').toString(),
      'breed': (body['breed'] ?? '').toString(),
      if (body['dateOfBirth'] != null) 'dateOfBirth': body['dateOfBirth'].toString(),
      if (body['weight'] != null) 'weight': (body['weight'] as num).toDouble(),
      if (body['gender'] != null) 'gender': body['gender'].toString(),
      'bio': (body['bio'] ?? '').toString(),
      'insurance': (body['insurance'] ?? '').toString(),
      if (body['neuteredDate'] != null) 'neuteredDate': body['neuteredDate'].toString(),
      'neuterDismissed': body['neuterDismissed'] == true,
      'chipId': (body['chipId'] ?? '').toString(),
      'chipDismissed': body['chipDismissed'] == true,
      if (body['photoPath'] != null) 'photoPath': body['photoPath'].toString(),
      if (body['vetId'] != null) 'vetId': body['vetId'].toString(),
      if (body['colorValue'] != null) 'colorValue': body['colorValue'] as int,
      'passedAway': body['passedAway'] == true,
    },
  );

  final updated = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE id = @id'),
    parameters: {'id': petId},
  );
  _jsonResponse(request, 200, _petRowToJson(updated.first));
}

Future<void> _deletePetRecord(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final petId = request.uri.pathSegments.last;
  await _pool.execute(
    Sql.named('DELETE FROM pets WHERE id = @id AND user_id = @userId'),
    parameters: {'id': petId, 'userId': userId},
  );
  _jsonResponse(request, 200, {'message': 'Pet deleted'});
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

  final existing = await _pool.execute(
    Sql.named('SELECT id FROM users WHERE email = @email'),
    parameters: {'email': email},
  );
  if (existing.isNotEmpty) {
    _jsonResponse(request, 409, {'error': 'An account with this email already exists'});
    return;
  }

  final hash = _hashPassword(password);
  final result = await _pool.execute(
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

  await _pool.execute(
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

  final result = await _pool.execute(
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

  await _pool.execute(
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

  final result = await _pool.execute(
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
    await _pool.execute(
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
  final result = await _pool.execute(
    Sql.named('SELECT id, email, name, first_name, last_name, category, bio, photo_url, locale, created_at, updated_at FROM users WHERE id = @id'),
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
  final locale = body['locale'] as String? ?? 'en';
  final name = '$firstName $lastName'.trim();

  final result = await _pool.execute(
    Sql.named('''
      UPDATE users SET
        name = @name,
        first_name = @firstName,
        last_name = @lastName,
        category = @category,
        bio = @bio,
        locale = @locale,
        updated_at = NOW()
      WHERE id = @id
      RETURNING id, email, name, first_name, last_name, category, bio, photo_url, locale, created_at, updated_at
    '''),
    parameters: {
      'id': userId,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'category': category,
      'bio': bio,
      'locale': locale,
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

  final result = await _pool.execute(
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
  final userResult = await _pool.execute(
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
  await _pool.execute(
    Sql.named('UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
    parameters: {'id': userId, 'hash': newHash},
  );

  await _pool.execute(
    Sql.named('DELETE FROM refresh_tokens WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  _jsonResponse(request, 200, {'message': 'Password changed successfully. Please log in again.'});
}

Future<void> _authForgotPassword(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  if (email.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Email is required'});
    return;
  }

  final recentCount = await _pool.execute(
    Sql.named('''
      SELECT COUNT(*) as cnt FROM password_reset_tokens
      WHERE created_at > NOW() - INTERVAL '1 hour'
      AND user_id IN (SELECT id FROM users WHERE email = @email)
    '''),
    parameters: {'email': email},
  );
  final count = recentCount.isNotEmpty ? (recentCount.first.toColumnMap()['cnt'] ?? 0) : 0;
  if (count is int && count >= 5) {
    _jsonResponse(request, 429, {'error': 'Too many reset attempts. Please try again later.'});
    return;
  }

  final userResult = await _pool.execute(
    Sql.named('SELECT id FROM users WHERE email = @email'),
    parameters: {'email': email},
  );

  if (userResult.isEmpty) {
    _jsonResponse(request, 200, {'message': 'If an account with that email exists, a reset code has been sent.'});
    return;
  }

  final userId = userResult.first.toColumnMap()['id'];

  await _pool.execute(
    Sql.named('UPDATE password_reset_tokens SET used = TRUE WHERE user_id = @userId AND used = FALSE'),
    parameters: {'userId': userId},
  );

  final rng = Random.secure();
  final code = List.generate(6, (_) => rng.nextInt(10)).join();

  await _pool.execute(
    Sql.named('''
      INSERT INTO password_reset_tokens (user_id, code, expires_at)
      VALUES (@userId, @code, NOW() + INTERVAL '15 minutes')
    '''),
    parameters: {'userId': userId, 'code': code},
  );

  print('Password reset code for $email: $code');

  _jsonResponse(request, 200, {'message': 'If an account with that email exists, a reset code has been sent.'});
}

Future<void> _authResetPassword(HttpRequest request) async {
  final body = await _readJson(request);
  if (body == null) return;

  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final code = (body['code'] as String? ?? '').trim();
  final newPassword = body['new_password'] as String? ?? body['newPassword'] as String? ?? '';

  if (email.isEmpty || code.isEmpty || newPassword.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Email, code, and new password are required'});
    return;
  }

  if (newPassword.length < 6) {
    _jsonResponse(request, 400, {'error': 'Password must be at least 6 characters'});
    return;
  }

  final userResult = await _pool.execute(
    Sql.named('SELECT id FROM users WHERE email = @email'),
    parameters: {'email': email},
  );

  if (userResult.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Invalid email or reset code'});
    return;
  }

  final userId = userResult.first.toColumnMap()['id'];

  final tokenResult = await _pool.execute(
    Sql.named('''
      SELECT id FROM password_reset_tokens
      WHERE user_id = @userId AND code = @code AND used = FALSE AND expires_at > NOW()
      ORDER BY created_at DESC LIMIT 1
    '''),
    parameters: {'userId': userId, 'code': code},
  );

  if (tokenResult.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Invalid or expired reset code'});
    return;
  }

  final tokenId = tokenResult.first.toColumnMap()['id'];

  final newHash = _hashPassword(newPassword);
  await _pool.execute(
    Sql.named('UPDATE users SET password_hash = @hash, updated_at = NOW() WHERE id = @id'),
    parameters: {'id': userId, 'hash': newHash},
  );

  await _pool.execute(
    Sql.named('UPDATE password_reset_tokens SET used = TRUE WHERE id = @id'),
    parameters: {'id': tokenId},
  );

  await _pool.execute(
    Sql.named('DELETE FROM refresh_tokens WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  _jsonResponse(request, 200, {'message': 'Password has been reset successfully. You can now log in with your new password.'});
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

  final result = await _pool.execute(Sql.named(query),
      parameters: params.isEmpty ? null : params);
  final entries = result.map(_rowToMap).toList();
  _jsonResponse(request, 200, entries);
}

Future<void> _getHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _pool.execute(
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
  final frequencyInterval = body['frequency_interval'] as int? ?? 1;
  final repeatEndDate = body['repeat_end_date'] as String?;
  final startDate = body['start_date'] as String? ?? '';
  final nextDueDate = body['next_due_date'] as String? ?? startDate;
  final notes = body['notes'] as String? ?? '';
  final petId = body['pet_id'] as String? ?? '';
  final healthIssueId = body['health_issue_id'] != null ? int.tryParse(body['health_issue_id'].toString()) : null;
  final remindDaysBefore = body['remind_days_before'] as int? ?? 1;

  if (name.isEmpty || type.isEmpty || frequency.isEmpty || startDate.isEmpty) {
    _jsonResponse(
        request, 400, {'error': 'name, type, frequency, start_date required'});
    return;
  }

  final result = await _pool.execute(
    Sql.named('''
      INSERT INTO health_entries (pet_id, name, type, dosage, frequency, frequency_days, frequency_interval, repeat_end_date, start_date, next_due_date, notes, health_issue_id, remind_days_before)
      VALUES (@petId, @name, @type, @dosage, @frequency, @frequencyDays, @frequencyInterval, ${repeatEndDate != null ? '@repeatEndDate::date' : 'NULL'}, @startDate::date, @nextDueDate::timestamptz, @notes, ${healthIssueId != null ? '@healthIssueId' : 'NULL'}, @remindDaysBefore)
      RETURNING *
    '''),
    parameters: {
      'petId': petId,
      'name': name,
      'type': type,
      'dosage': dosage,
      'frequency': frequency,
      'frequencyDays': frequencyDays,
      'frequencyInterval': frequencyInterval,
      if (repeatEndDate != null) 'repeatEndDate': repeatEndDate,
      'startDate': startDate,
      'nextDueDate': nextDueDate,
      'notes': notes,
      if (healthIssueId != null) 'healthIssueId': healthIssueId,
      'remindDaysBefore': remindDaysBefore,
    },
  );

  if (healthIssueId != null) {
    final createdId = result.first.toColumnMap()['id'].toString();
    if (createdId.isNotEmpty) {
      await _pool.execute(
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
      final prefResult = await _pool.execute(
        Sql.named('SELECT notify_completed FROM notification_preferences WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      final notifyCompleted = prefResult.isEmpty || (prefResult.first.toColumnMap()['notify_completed'] as bool? ?? true);
      if (notifyCompleted) {
        final petName = body['pet_name'] as String? ?? '';
        final petPrefix = petName.isNotEmpty ? '$petName - ' : '';
        final locale = await _getUserLocale(userId);
        await _pool.execute(
          Sql.named('''
            INSERT INTO notifications (user_id, pet_id, health_entry_id, title, message, type)
            VALUES (@userId, @petId, @entryId, @title, @message, 'completed')
          '''),
          parameters: {
            'userId': userId,
            'petId': petId,
            'entryId': createdRow['id'].toString(),
            'title': _t(locale, 'completed_title', {'pet': petPrefix, 'name': name}),
            'message': _t(locale, 'completed_message', {'name': name}),
          },
        );
      }
    }
  }

  _jsonResponse(request, 201, createdRow);

  await _createGeneralNotification(request, petId, 'event_created', 'event_created_msg', name, type);
}

Future<void> _updateHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _pool.execute(
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

  final result = await _pool.execute(
    Sql.named('''
      UPDATE health_entries SET
        name = @name, type = @type, dosage = @dosage,
        frequency = @frequency, frequency_days = @frequencyDays,
        frequency_interval = @frequencyInterval,
        repeat_end_date = ${repeatEndDateVal != null ? '@repeatEndDate::date' : 'NULL'},
        start_date = @startDate::date, next_due_date = @nextDueDate::timestamptz,
        notes = @notes, health_issue_id = ${newHealthIssueId != null ? '@healthIssueId' : 'NULL'},
        remind_days_before = @remindDaysBefore,
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
      'frequencyInterval': body['frequency_interval'] ?? row['frequency_interval'] ?? 1,
      if (repeatEndDateVal != null) 'repeatEndDate': repeatEndDateVal.toString(),
      'startDate': body['start_date'] ?? row['start_date'],
      'nextDueDate': body['next_due_date'] ?? row['next_due_date'],
      'notes': body['notes'] ?? row['notes'],
      if (newHealthIssueId != null) 'healthIssueId': newHealthIssueId,
      'remindDaysBefore': body['remind_days_before'] ?? row['remind_days_before'] ?? 1,
    },
  );

  if (hasHealthIssueId) {
    if (oldHealthIssueId != null && oldHealthIssueId != newHealthIssueId) {
      await _pool.execute(
        Sql.named('DELETE FROM health_issue_events WHERE health_issue_id = @oldId AND health_entry_id = @entryId::uuid'),
        parameters: {'oldId': oldHealthIssueId, 'entryId': id},
      );
    }
    if (newHealthIssueId != null && newHealthIssueId != oldHealthIssueId) {
      await _pool.execute(
        Sql.named('INSERT INTO health_issue_events (health_issue_id, health_entry_id) VALUES (@newId, @entryId::uuid) ON CONFLICT DO NOTHING'),
        parameters: {'newId': newHealthIssueId, 'entryId': id},
      );
    }
  }

  final updatedRow = _rowToMap(result.first);
  _jsonResponse(request, 200, updatedRow);

  final updatedName = updatedRow['name']?.toString() ?? '';
  final updatedPetId = updatedRow['pet_id']?.toString() ?? '';
  await _createGeneralNotification(request, updatedPetId, 'event_updated', 'event_updated_msg', updatedName);
}

Future<void> _deleteHealthEntry(HttpRequest request) async {
  final id = request.uri.pathSegments.last;

  final existing = await _pool.execute(
    Sql.named('SELECT name, pet_id FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );
  final entryName = existing.isNotEmpty ? existing.first.toColumnMap()['name']?.toString() ?? '' : '';
  final entryPetId = existing.isNotEmpty ? existing.first.toColumnMap()['pet_id']?.toString() ?? '' : '';

  final result = await _pool.execute(
    Sql.named('DELETE FROM health_entries WHERE id = @id RETURNING id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  _jsonResponse(request, 200, {'deleted': true});

  if (entryName.isNotEmpty) {
    await _createGeneralNotification(request, entryPetId, 'event_deleted', 'event_deleted_msg', entryName);
  }
}

Future<void> _markTaken(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final id = segments[segments.length - 2];
  final body = await _readJson(request);

  final existing = await _pool.execute(
    Sql.named('SELECT * FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  final row = _rowToMap(existing.first);
  final historyNotes = body?['notes'] as String? ?? '';

  await _pool.execute(
    Sql.named('''
      INSERT INTO health_history (entry_id, notes)
      VALUES (@entryId, @notes)
    '''),
    parameters: {'entryId': id, 'notes': historyNotes},
  );

  final frequency = row['frequency'] as String;
  final interval = (row['frequency_interval'] as int?) ?? 1;
  final currentDue = DateTime.parse(row['next_due_date'].toString());
  final repeatEndDateStr = row['repeat_end_date']?.toString();
  final repeatEndDate = repeatEndDateStr != null ? DateTime.tryParse(repeatEndDateStr) : null;
  DateTime nextDue;

  switch (frequency) {
    case 'once':
      nextDue = DateTime(9999, 12, 31);
      break;
    case 'daily':
      nextDue = currentDue.add(Duration(days: 1 * interval));
      break;
    case 'weekly':
      nextDue = currentDue.add(Duration(days: 7 * interval));
      break;
    case 'monthly':
      nextDue = DateTime(currentDue.year, currentDue.month + interval, currentDue.day,
          currentDue.hour, currentDue.minute);
      break;
    case 'yearly':
      nextDue = DateTime(currentDue.year + interval, currentDue.month, currentDue.day,
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

  final updated = await _pool.execute(
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
      final prefResult = await _pool.execute(
        Sql.named('SELECT notify_completed FROM notification_preferences WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      final notifyCompleted = prefResult.isEmpty || (prefResult.first.toColumnMap()['notify_completed'] as bool? ?? true);
      if (notifyCompleted) {
        final entryName = row['name'].toString();
        final petId = row['pet_id'].toString();
        final petName = body?['pet_name'] as String? ?? '';
        final petPrefix = petName.isNotEmpty ? '$petName - ' : '';
        final locale = await _getUserLocale(userId);
        await _pool.execute(
          Sql.named('''
            INSERT INTO notifications (user_id, pet_id, health_entry_id, title, message, type)
            VALUES (@userId, @petId, @entryId, @title, @message, 'completed')
          '''),
          parameters: {
            'userId': userId,
            'petId': petId,
            'entryId': id,
            'title': _t(locale, 'completed_title', {'pet': petPrefix, 'name': entryName}),
            'message': _t(locale, 'completed_message', {'name': entryName}),
          },
        );
      }
    }
  }

  _jsonResponse(request, 200, _rowToMap(updated.first));
}

Future<void> _undoComplete(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final id = segments[segments.length - 2];

  final existing = await _pool.execute(
    Sql.named('SELECT * FROM health_entries WHERE id = @id'),
    parameters: {'id': id},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Entry not found'});
    return;
  }

  final row = _rowToMap(existing.first);
  final frequency = row['frequency'] as String;
  final nextDue = DateTime.parse(row['next_due_date'].toString());

  if (frequency != 'once' || nextDue.year < 9999) {
    _jsonResponse(request, 400, {'error': 'Entry is not completed'});
    return;
  }

  final startDate = row['start_date'].toString();

  final updated = await _pool.execute(
    Sql.named('''
      UPDATE health_entries SET next_due_date = @nextDue, updated_at = NOW()
      WHERE id = @id RETURNING *
    '''),
    parameters: {'id': id, 'nextDue': startDate},
  );

  _jsonResponse(request, 200, _rowToMap(updated.first));
}

Future<void> _getHistory(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final id = segments[segments.length - 2];

  final result = await _pool.execute(
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

  final result = await _pool.execute(Sql.named(query),
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
  final result = await _pool.execute(
    Sql.named('SELECT * FROM vets ORDER BY name ASC'),
  );
  final vets = result.map(_vetRowToMap).toList();
  _jsonResponse(request, 200, vets);
}

Future<void> _getVet(HttpRequest request) async {
  final id = request.uri.pathSegments.last;
  final result = await _pool.execute(
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

  final result = await _pool.execute(
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

  final existing = await _pool.execute(
    Sql.named('SELECT * FROM vets WHERE id = @id'),
    parameters: {'id': int.tryParse(id) ?? 0},
  );

  if (existing.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Vet not found'});
    return;
  }

  final row = _vetRowToMap(existing.first);

  final result = await _pool.execute(
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
  final result = await _pool.execute(
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

  final result = await _pool.execute(Sql.named(query),
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

  final result = await _pool.execute(
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

  final existing = await _pool.execute(
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

  final result = await _pool.execute(
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
  final result = await _pool.execute(
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

  final result = await _pool.execute(
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
  final result = await _pool.execute(
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

  final countResult = await _pool.execute(
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

  final result = await _pool.execute(
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

  final result = await _pool.execute(
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

  await _pool.execute(
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

  await _pool.execute(
    Sql.named('''
      INSERT INTO pet_access (pet_id, user_id, role)
      VALUES (@petId, @userId, 'guardian')
      ON CONFLICT (pet_id, user_id) DO UPDATE SET role = 'guardian'
    '''),
    parameters: {'petId': petId, 'userId': authUserId},
  );

  final existingAccess = await _pool.execute(
    Sql.named('SELECT share_code FROM pet_access WHERE pet_id = @petId AND user_id = @userId AND share_code IS NOT NULL'),
    parameters: {'petId': petId, 'userId': authUserId},
  );

  String code;
  if (existingAccess.isNotEmpty && existingAccess.first.toColumnMap()['share_code'] != null) {
    code = existingAccess.first.toColumnMap()['share_code'].toString();
  } else {
    code = _generateShareCode();
    await _pool.execute(
      Sql.named('UPDATE pet_access SET share_code = @code WHERE pet_id = @petId AND user_id = @userId'),
      parameters: {'code': code, 'petId': petId, 'userId': authUserId},
    );
  }

  final existingShared = await _pool.execute(
    Sql.named('SELECT id FROM shared_pets WHERE pet_id = @petId'),
    parameters: {'petId': petId},
  );

  if (existingShared.isNotEmpty) {
    await _pool.execute(
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
    await _pool.execute(
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

  await _createGeneralNotification(request, petId, 'share_granted', 'share_granted_msg');
}

Future<void> _getShare(HttpRequest request) async {
  final code = request.uri.pathSegments.last;

  final result = await _pool.execute(
    Sql.named('SELECT * FROM shared_pets WHERE share_code = @code'),
    parameters: {'code': code},
  );

  Map<String, dynamic>? guardianInfo;
  final accessResult = await _pool.execute(
    Sql.named('''
      SELECT pa.*, u.name AS user_name, u.first_name, u.last_name, u.category, u.bio, u.photo_url
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
    var gFirstName = (aCols['first_name'] ?? '').toString();
    var gLastName = (aCols['last_name'] ?? '').toString();
    if (gFirstName.isEmpty && gLastName.isEmpty) {
      final fallback = (aCols['user_name'] ?? '').toString().trim();
      if (fallback.isNotEmpty) {
        final parts = fallback.split(' ');
        gFirstName = parts.first;
        if (parts.length > 1) gLastName = parts.sublist(1).join(' ');
      }
    }
    guardianInfo = {
      'user_id': aCols['user_id'].toString(),
      'first_name': gFirstName,
      'last_name': gLastName,
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

  final healthResult = await _pool.execute(
    Sql.named(
        'SELECT * FROM health_entries WHERE pet_id = @petId ORDER BY next_due_date ASC'),
    parameters: {'petId': petId},
  );
  final healthEntries = healthResult.map(_rowToMap).toList();

  final vetId = (petData is Map) ? petData['vetId'] : null;
  Map<String, dynamic>? vet;
  if (vetId != null && vetId.toString().isNotEmpty) {
    final vetResult = await _pool.execute(
      Sql.named('SELECT * FROM vets WHERE id = @id'),
      parameters: {'id': int.tryParse(vetId.toString()) ?? 0},
    );
    if (vetResult.isNotEmpty) {
      vet = _vetRowToMap(vetResult.first);
    }
  }

  Map<String, dynamic>? owner = guardianInfo;
  if (owner == null && shareUserId != null) {
    final ownerResult = await _pool.execute(
      Sql.named('SELECT id, email, name, first_name, last_name, category, bio, photo_url, created_at, updated_at FROM users WHERE id = @id'),
      parameters: {'id': shareUserId},
    );
    if (ownerResult.isNotEmpty) {
      final ownerRow = ownerResult.first.toColumnMap();
      var ownerFirstName = (ownerRow['first_name'] ?? '').toString();
      var ownerLastName = (ownerRow['last_name'] ?? '').toString();
      if (ownerFirstName.isEmpty && ownerLastName.isEmpty) {
        final fallback = (ownerRow['name'] ?? '').toString().trim();
        if (fallback.isNotEmpty) {
          final parts = fallback.split(' ');
          ownerFirstName = parts.first;
          if (parts.length > 1) ownerLastName = parts.sublist(1).join(' ');
        }
      }
      owner = {
        'user_id': ownerRow['id'].toString(),
        'first_name': ownerFirstName,
        'last_name': ownerLastName,
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

  final accessResult = await _pool.execute(
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

  await _pool.execute(
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

  final userResult = await _pool.execute(
    Sql.named('SELECT id, name, first_name, last_name, category, bio, photo_url FROM users WHERE id = @id'),
    parameters: {'id': userId},
  );

  Map<String, dynamic> userInfo = {};
  if (userResult.isNotEmpty) {
    final u = userResult.first.toColumnMap();
    var firstName = (u['first_name'] ?? '').toString();
    var lastName = (u['last_name'] ?? '').toString();
    if (firstName.isEmpty && lastName.isEmpty) {
      final fallbackName = (u['name'] ?? '').toString().trim();
      if (fallbackName.isNotEmpty) {
        final parts = fallbackName.split(' ');
        firstName = parts.first;
        if (parts.length > 1) lastName = parts.sublist(1).join(' ');
      }
    }
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

Future<void> _markPetPassedAway(HttpRequest request) async {
  final payload = await _authenticateRequest(request);
  if (payload == null) {
    _jsonResponse(request, 401, {'error': 'Not authenticated'});
    return;
  }
  final userId = int.parse(payload['sub'].toString());

  final segments = request.uri.pathSegments;
  final petId = segments[2];
  final body = await _readJson(request);
  final petName = (body?['pet_name'] as String?) ?? 'Your pet';

  try {
    final accessRows = await _pool.execute(
      Sql.named('SELECT user_id FROM pet_access WHERE pet_id = @petId AND user_id != @userId'),
      parameters: {'petId': petId, 'userId': userId},
    );

    int notifiedCount = 0;
    for (final row in accessRows) {
      final sharedUserId = row.toColumnMap()['user_id'] as int;
      final sharedLocale = await _getUserLocale(sharedUserId);
      await _pool.execute(
        Sql.named('''
          INSERT INTO notifications (user_id, pet_id, title, message, type)
          VALUES (@userId, @petId, @title, @message, 'memorial')
        '''),
        parameters: {
          'userId': sharedUserId,
          'petId': petId,
          'title': _t(sharedLocale, 'memorial_title', {'name': petName}),
          'message': _t(sharedLocale, 'memorial_message', {'name': petName}),
        },
      );
      notifiedCount++;
    }

    await _pool.execute(
      Sql.named('DELETE FROM notifications WHERE pet_id = @petId AND type IN (\'reminder\', \'overdue\') AND is_read = FALSE'),
      parameters: {'petId': petId},
    );

    _jsonResponse(request, 200, {'success': true, 'pet_id': petId, 'notified_count': notifiedCount});
  } catch (e) {
    print('Error marking pet passed away: $e');
    _jsonResponse(request, 500, {'error': 'Failed to process passed away request'});
  }
}

Future<void> _deletePetData(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final petId = segments[2];

  try {
    await _pool.execute(
      Sql.named('DELETE FROM health_issue_events WHERE health_issue_id IN (SELECT id FROM health_issues WHERE pet_id = @petId)'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('UPDATE health_entries SET health_issue_id = NULL WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('DELETE FROM health_issues WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    final photoRows = await _pool.execute(
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

    await _pool.execute(
      Sql.named('DELETE FROM health_event_photos WHERE event_id IN (SELECT id::text FROM health_entries WHERE pet_id = @petId)'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('DELETE FROM health_entries WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('DELETE FROM weight_entries WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('DELETE FROM notifications WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
      Sql.named('DELETE FROM pet_access WHERE pet_id = @petId'),
      parameters: {'petId': petId},
    );

    await _pool.execute(
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

  final callerAccess = await _pool.execute(
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
    final result = await _pool.execute(
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
      final result = await _pool.execute(
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

  final callerAccess = await _pool.execute(
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
    final guardianCount = await _pool.execute(
      Sql.named('SELECT COUNT(*) as cnt FROM pet_access WHERE pet_id = @petId AND role = \'guardian\''),
      parameters: {'petId': petId},
    );
    final count = guardianCount.first.toColumnMap()['cnt'] as int;
    if (count <= 1) {
      _jsonResponse(request, 400, {'error': 'Cannot demote the last guardian'});
      return;
    }
  }

  final result = await _pool.execute(
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

  final callerAccess = await _pool.execute(
    Sql.named('SELECT role FROM pet_access WHERE pet_id = @petId AND user_id = @userId'),
    parameters: {'petId': petId, 'userId': callerId},
  );

  if (callerAccess.isEmpty || callerAccess.first.toColumnMap()['role'].toString() != 'guardian') {
    _jsonResponse(request, 403, {'error': 'Only guardians can remove access'});
    return;
  }

  if (targetUserId == callerId) {
    final guardianCount = await _pool.execute(
      Sql.named('SELECT COUNT(*) as cnt FROM pet_access WHERE pet_id = @petId AND role = \'guardian\''),
      parameters: {'petId': petId},
    );
    final count = guardianCount.first.toColumnMap()['cnt'] as int;
    if (count <= 1) {
      _jsonResponse(request, 400, {'error': 'Cannot remove the last guardian'});
      return;
    }
  }

  final result = await _pool.execute(
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
  final result = await _pool.execute(
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
  final result = await _pool.execute(
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

  final result = await _pool.execute(
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
  await _pool.execute(
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
  var result = await _pool.execute(
    Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  if (result.isEmpty) {
    await _pool.execute(
      Sql.named('INSERT INTO notification_preferences (user_id) VALUES (@userId)'),
      parameters: {'userId': userId},
    );
    result = await _pool.execute(
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

  await _pool.execute(
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

  final result = await _pool.execute(
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

  var prefResult = await _pool.execute(
    Sql.named('SELECT * FROM notification_preferences WHERE user_id = @userId'),
    parameters: {'userId': userId},
  );

  bool emailEnabled = false;
  if (prefResult.isNotEmpty) {
    final prefRow = prefResult.first.toColumnMap();
    emailEnabled = prefRow['email_reminders_enabled'] as bool;
  }

  final dueEntries = await _pool.execute(
    Sql.named('''
      SELECT he.* FROM health_entries he
      JOIN pets p ON p.id::text = he.pet_id
      WHERE he.next_due_date <= NOW() + make_interval(days => he.remind_days_before)
      AND he.next_due_date IS NOT NULL
      AND (p.user_id = @userId
           OR p.id::text IN (SELECT pet_id FROM pet_access WHERE user_id = @userId))
    '''),
    parameters: {'userId': userId},
  );

  int created = 0;
  String? userEmail;

  if (emailEnabled) {
    final userResult = await _pool.execute(
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

    final existing = await _pool.execute(
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
    final locale = await _getUserLocale(userId);
    final title = isOverdue
        ? _t(locale, 'overdue_title', {'pet': petPrefix, 'name': entryName})
        : _t(locale, 'reminder_title', {'pet': petPrefix, 'name': entryName});
    final message = isOverdue
        ? _t(locale, 'overdue_message', {'name': entryName, 'date': nextDue})
        : _t(locale, 'reminder_message', {'name': entryName, 'date': nextDue});

    await _pool.execute(
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

Future<void> _createGeneralNotification(HttpRequest request, String petId, String titleKey, String messageKey, [String itemName = '', String itemType = '']) async {
  try {
    final payload = await _authenticateRequest(request);
    if (payload == null) return;
    final userId = int.parse(payload['sub'].toString());
    final locale = await _getUserLocale(userId);

    String petPrefix = '';
    if (petId.isNotEmpty) {
      final petResult = await _pool.execute(
        Sql.named('SELECT name FROM pets WHERE id::text = @id'),
        parameters: {'id': petId},
      );
      if (petResult.isNotEmpty) {
        petPrefix = '${petResult.first.toColumnMap()['name']} - ';
      }
    }

    final params = {'pet': petPrefix, 'name': itemName, 'type': itemType};
    final title = _t(locale, titleKey, params);
    final message = _t(locale, messageKey, params);

    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, title, message, type)
        VALUES (@userId, ${petId.isNotEmpty ? '@petId' : 'NULL'}, @title, @message, 'general')
      '''),
      parameters: {
        'userId': userId,
        if (petId.isNotEmpty) 'petId': petId,
        'title': title,
        'message': message,
      },
    );
  } catch (e) {
    print('General notification error: $e');
  }
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

  final result = await _pool.execute(
    Sql.named('SELECT * FROM health_issues WHERE pet_id = @petId ORDER BY created_at DESC'),
    parameters: {'petId': petId},
  );

  final issues = <Map<String, dynamic>>[];
  for (final row in result) {
    final issue = _healthIssueToMap(row);
    final issueId = int.tryParse(issue['id'].toString()) ?? 0;
    final eventsResult = await _pool.execute(
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

  final result = await _pool.execute(
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

  await _createGeneralNotification(request, petId, 'issue_created', 'issue_created_msg', title);
}

Future<void> _updateHealthIssue(HttpRequest request) async {
  final id = int.tryParse(request.uri.pathSegments.last);
  if (id == null) {
    _jsonResponse(request, 400, {'error': 'Invalid issue ID'});
    return;
  }

  final body = await _readJson(request);
  if (body == null) return;

  final existing = await _pool.execute(
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

  final result = await _pool.execute(
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
  final eventsResult = await _pool.execute(
    Sql.named('SELECT health_entry_id FROM health_issue_events WHERE health_issue_id = @issueId'),
    parameters: {'issueId': id},
  );
  issue['event_ids'] = eventsResult.map((r) => r.toColumnMap()['health_entry_id'].toString()).toList();
  _jsonResponse(request, 200, issue);

  final updatedTitle = issue['title']?.toString() ?? '';
  final updatedPetId = issue['pet_id']?.toString() ?? '';
  await _createGeneralNotification(request, updatedPetId, 'issue_updated', 'issue_updated_msg', updatedTitle);
}

Future<void> _deleteHealthIssue(HttpRequest request) async {
  final id = int.tryParse(request.uri.pathSegments.last);
  if (id == null) {
    _jsonResponse(request, 400, {'error': 'Invalid issue ID'});
    return;
  }

  final existingIssue = await _pool.execute(
    Sql.named('SELECT title, pet_id FROM health_issues WHERE id = @id'),
    parameters: {'id': id},
  );
  final issueTitle = existingIssue.isNotEmpty ? existingIssue.first.toColumnMap()['title']?.toString() ?? '' : '';
  final issuePetId = existingIssue.isNotEmpty ? existingIssue.first.toColumnMap()['pet_id']?.toString() ?? '' : '';

  final result = await _pool.execute(
    Sql.named('DELETE FROM health_issues WHERE id = @id RETURNING id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Health issue not found'});
    return;
  }

  await _pool.execute(
    Sql.named('UPDATE health_entries SET health_issue_id = NULL WHERE health_issue_id = @id'),
    parameters: {'id': id},
  );

  _jsonResponse(request, 200, {'deleted': true});

  if (issueTitle.isNotEmpty) {
    await _createGeneralNotification(request, issuePetId, 'issue_deleted', 'issue_deleted_msg', issueTitle);
  }
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

  final issueExists = await _pool.execute(
    Sql.named('SELECT id FROM health_issues WHERE id = @id'),
    parameters: {'id': issueId},
  );
  if (issueExists.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Health issue not found'});
    return;
  }

  await _pool.execute(
    Sql.named('INSERT INTO health_issue_events (health_issue_id, health_entry_id) VALUES (@issueId, @entryId::uuid) ON CONFLICT DO NOTHING'),
    parameters: {'issueId': issueId, 'entryId': entryId},
  );

  await _pool.execute(
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

  await _pool.execute(
    Sql.named('DELETE FROM health_issue_events WHERE health_issue_id = @issueId AND health_entry_id = @entryId::uuid'),
    parameters: {'issueId': issueId, 'entryId': entryId},
  );

  await _pool.execute(
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
    'frequency_interval': cols['frequency_interval'] ?? 1,
    'repeat_end_date': cols['repeat_end_date']?.toString(),
    'start_date': cols['start_date'].toString(),
    'next_due_date': cols['next_due_date'].toString(),
    'notes': cols['notes'].toString(),
    'health_issue_id': cols['health_issue_id']?.toString(),
    'health_issue_title': cols.containsKey('health_issue_title') ? cols['health_issue_title']?.toString() : null,
    'remind_days_before': cols['remind_days_before'] ?? 1,
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

// ── Premium status (RevenueCat) ──────────────────────────────

Future<void> _getPremiumStatus(HttpRequest request) async {
  final segments = request.uri.pathSegments;
  final userId = segments.last;

  final rcSecret = Platform.environment['REVENUECAT_API_SECRET'] ?? '';
  if (rcSecret.isEmpty) {
    _jsonResponse(request, 200, {
      'is_premium': false,
      'error': 'RevenueCat not configured',
    });
    return;
  }

  try {
    final client = HttpClient();
    final rcRequest = await client.getUrl(
      Uri.parse('https://api.revenuecat.com/v1/subscribers/$userId'),
    );
    rcRequest.headers.set('Authorization', 'Bearer $rcSecret');
    rcRequest.headers.set('Content-Type', 'application/json');

    final rcResponse = await rcRequest.close();
    final rcBody = await utf8.decoder.bind(rcResponse).join();
    client.close();

    if (rcResponse.statusCode != 200) {
      _jsonResponse(request, 200, {
        'is_premium': false,
        'user_id': userId,
      });
      return;
    }

    final data = json.decode(rcBody) as Map<String, dynamic>;
    final subscriber = data['subscriber'] as Map<String, dynamic>? ?? {};
    final entitlements = subscriber['entitlements'] as Map<String, dynamic>? ?? {};

    bool isPremium = false;
    String? expires;
    String? productId;

    for (final entry in entitlements.entries) {
      final ent = entry.value as Map<String, dynamic>;
      final expiresDate = ent['expires_date'] as String?;
      if (expiresDate != null) {
        final expiry = DateTime.tryParse(expiresDate);
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          isPremium = true;
          expires = expiresDate;
          productId = ent['product_identifier'] as String?;
          break;
        }
      } else {
        isPremium = true;
        productId = ent['product_identifier'] as String?;
        break;
      }
    }

    _jsonResponse(request, 200, {
      'is_premium': isPremium,
      'user_id': userId,
      if (expires != null) 'expires': expires,
      if (productId != null) 'product_id': productId,
    });
  } catch (e) {
    print('RevenueCat API error: $e');
    _jsonResponse(request, 200, {
      'is_premium': false,
      'user_id': userId,
      'error': 'Failed to check subscription status',
    });
  }
}

// ── Organization helpers ──────────────────────────────────────

Map<String, dynamic> _orgRowToJson(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'name': (cols['name'] ?? '').toString(),
    'type': (cols['type'] ?? 'professional').toString(),
    'email': (cols['email'] ?? '').toString(),
    'phone': (cols['phone'] ?? '').toString(),
    'address': (cols['address'] ?? '').toString(),
    'website': (cols['website'] ?? '').toString(),
    'bio': (cols['bio'] ?? '').toString(),
    'photo_url': (cols['photo_url'] ?? '').toString(),
    'created_by': cols['created_by'].toString(),
    'created_at': cols['created_at']?.toString(),
    'updated_at': cols['updated_at']?.toString(),
  };
}

Future<Map<String, dynamic>?> _requireOrgMember(HttpRequest request, int orgId) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return null;
  }
  final r = await _pool.execute(
    Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (r.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Not a member of this organization'});
    return null;
  }
  return {'userId': userId, 'role': r.first.toColumnMap()['role'].toString()};
}

Future<int?> _requireOrgSuperUser(HttpRequest request, int orgId) async {
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return null;
  if (member['role'] != 'super_user') {
    _jsonResponse(request, 403, {'error': 'Super user access required'});
    return null;
  }
  return member['userId'] as int;
}

// ── Organization CRUD ────────────────────────────────────────

Future<void> _getOrganizations(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final result = await _pool.execute(
    Sql.named('''
      SELECT o.*, ou.role as member_role,
        (SELECT COUNT(*) FROM organization_users ou2 WHERE ou2.organization_id = o.id) as member_count,
        (SELECT COUNT(*) FROM pets p WHERE p.organization_id = o.id) as pet_count
      FROM organizations o
      JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = @userId
      ORDER BY o.name
    '''),
    parameters: {'userId': userId},
  );
  final orgs = result.map((row) {
    final m = _orgRowToJson(row);
    final cols = row.toColumnMap();
    m['role'] = (cols['member_role'] ?? 'member').toString();
    m['member_count'] = cols['member_count'];
    m['pet_count'] = cols['pet_count'];
    return m;
  }).toList();
  _jsonResponse(request, 200, orgs);
}

Future<void> _createOrganization(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final name = (body['name'] as String?)?.trim() ?? '';
  if (name.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Name is required'});
    return;
  }
  final type = body['type'] as String? ?? 'professional';
  final email = body['email'] as String? ?? '';
  final phone = body['phone'] as String? ?? '';
  final address = body['address'] as String? ?? '';
  final website = body['website'] as String? ?? '';
  final bio = body['bio'] as String? ?? '';

  final result = await _pool.execute(
    Sql.named('''
      INSERT INTO organizations (name, type, email, phone, address, website, bio, created_by)
      VALUES (@name, @type, @email, @phone, @address, @website, @bio, @createdBy)
      RETURNING *
    '''),
    parameters: {
      'name': name, 'type': type, 'email': email, 'phone': phone,
      'address': address, 'website': website, 'bio': bio, 'createdBy': userId,
    },
  );
  final org = _orgRowToJson(result.first);
  final orgId = int.parse(org['id']);

  await _pool.execute(
    Sql.named('''
      INSERT INTO organization_users (organization_id, user_id, role)
      VALUES (@orgId, @userId, 'super_user')
    '''),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  org['role'] = 'super_user';
  org['member_count'] = 1;
  org['pet_count'] = 0;
  _jsonResponse(request, 201, org);
}

Future<void> _getOrganization(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return;

  final result = await _pool.execute(
    Sql.named('''
      SELECT o.*,
        (SELECT COUNT(*) FROM organization_users ou WHERE ou.organization_id = o.id) as member_count,
        (SELECT COUNT(*) FROM pets p WHERE p.organization_id = o.id) as pet_count
      FROM organizations o WHERE o.id = @id
    '''),
    parameters: {'id': orgId},
  );
  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Organization not found'});
    return;
  }
  final org = _orgRowToJson(result.first);
  final cols = result.first.toColumnMap();
  org['role'] = member['role'];
  org['member_count'] = cols['member_count'];
  org['pet_count'] = cols['pet_count'];
  _jsonResponse(request, 200, org);
}

Future<void> _updateOrganization(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final name = body['name'] as String?;
  final type = body['type'] as String?;
  final email = body['email'] as String?;
  final phone = body['phone'] as String?;
  final address = body['address'] as String?;
  final website = body['website'] as String?;
  final bio = body['bio'] as String?;

  final result = await _pool.execute(
    Sql.named('''
      UPDATE organizations SET
        name = COALESCE(@name, name),
        type = COALESCE(@type, type),
        email = COALESCE(@email, email),
        phone = COALESCE(@phone, phone),
        address = COALESCE(@address, address),
        website = COALESCE(@website, website),
        bio = COALESCE(@bio, bio),
        updated_at = NOW()
      WHERE id = @id
      RETURNING *
    '''),
    parameters: {
      'id': orgId, 'name': name, 'type': type, 'email': email,
      'phone': phone, 'address': address, 'website': website, 'bio': bio,
    },
  );
  if (result.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Organization not found'});
    return;
  }
  _jsonResponse(request, 200, _orgRowToJson(result.first));
}

Future<void> _deleteOrganization(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final orgR = await _pool.execute(
    Sql.named('SELECT created_by FROM organizations WHERE id = @id'),
    parameters: {'id': orgId},
  );
  if (orgR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Organization not found'});
    return;
  }
  if (int.parse(orgR.first.toColumnMap()['created_by'].toString()) != userId) {
    _jsonResponse(request, 403, {'error': 'Only the creator can delete this organization'});
    return;
  }

  final petCount = await _pool.execute(
    Sql.named('SELECT COUNT(*) as cnt FROM pets WHERE organization_id = @id'),
    parameters: {'id': orgId},
  );
  final cnt = petCount.first.toColumnMap()['cnt'];
  if (cnt != null && (cnt as int) > 0) {
    _jsonResponse(request, 400, {'error': 'Transfer or remove all pets before deleting the organization'});
    return;
  }

  await _pool.execute(Sql.named('DELETE FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  _jsonResponse(request, 200, {'success': true});
}

Future<void> _uploadOrgPhoto(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final contentType = request.headers.contentType;
  if (contentType == null || contentType.primaryType != 'multipart') {
    _jsonResponse(request, 400, {'error': 'Multipart form data required'});
    return;
  }
  final boundary = contentType.parameters['boundary'];
  if (boundary == null) {
    _jsonResponse(request, 400, {'error': 'Missing boundary'});
    return;
  }

  final bytes = await request.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
  final bodyStr = String.fromCharCodes(bytes);
  final parts = bodyStr.split('--$boundary');

  for (final part in parts) {
    if (part.contains('name="photo"')) {
      final headerEnd = part.indexOf('\r\n\r\n');
      if (headerEnd == -1) continue;
      final photoBytes = bytes.sublist(
        bodyStr.indexOf(part) + headerEnd + 4,
        bodyStr.indexOf(part) + part.lastIndexOf('\r\n'),
      );
      if (photoBytes.length > 2 * 1024 * 1024) {
        _jsonResponse(request, 400, {'error': 'Photo must be less than 2MB'});
        return;
      }
      final fileName = 'org_${orgId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('uploads/$fileName');
      await file.writeAsBytes(photoBytes);
      final photoUrl = '/uploads/$fileName';
      await _pool.execute(
        Sql.named('UPDATE organizations SET photo_url = @url, updated_at = NOW() WHERE id = @id'),
        parameters: {'url': photoUrl, 'id': orgId},
      );
      _jsonResponse(request, 200, {'photo_url': photoUrl});
      return;
    }
  }
  _jsonResponse(request, 400, {'error': 'No photo found in request'});
}

// ── Organization Members ──────────────────────────────────────

Future<void> _getOrgMembers(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return;

  final result = await _pool.execute(
    Sql.named('''
      SELECT ou.id, ou.organization_id, ou.user_id, ou.role, ou.created_at,
        u.email, u.name, u.first_name, u.last_name, u.photo_url as user_photo_url
      FROM organization_users ou
      JOIN users u ON u.id = ou.user_id
      WHERE ou.organization_id = @orgId AND ou.role IN ('super_user', 'member')
      ORDER BY ou.created_at
    '''),
    parameters: {'orgId': orgId},
  );
  final members = result.map((row) {
    final cols = row.toColumnMap();
    return {
      'id': cols['id'].toString(),
      'organization_id': cols['organization_id'].toString(),
      'user_id': cols['user_id'].toString(),
      'role': cols['role'].toString(),
      'email': (cols['email'] ?? '').toString(),
      'name': (cols['name'] ?? '').toString(),
      'first_name': (cols['first_name'] ?? '').toString(),
      'last_name': (cols['last_name'] ?? '').toString(),
      'photo_url': (cols['user_photo_url'] ?? '').toString(),
      'created_at': cols['created_at']?.toString(),
    };
  }).toList();
  _jsonResponse(request, 200, members);
}

Future<void> _createOrgInvite(HttpRequest request) async {
  final path = request.uri.path;
  final orgId = int.parse(path.split('/')[3]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final email = (body['email'] as String?)?.trim().toLowerCase();
  final desiredRole = body['role']?.toString() ?? 'member';

  if (email != null && email.isNotEmpty) {
    final targetR = await _pool.execute(
      Sql.named('SELECT id, name, first_name, last_name FROM users WHERE LOWER(email) = @email'),
      parameters: {'email': email},
    );
    if (targetR.isEmpty) {
      _jsonResponse(request, 404, {'error': 'user_not_found'});
      return;
    }
    final targetUser = targetR.first.toColumnMap();
    final targetUserId = targetUser['id'] as int;

    final existingR = await _pool.execute(
      Sql.named('SELECT id, role FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
      parameters: {'orgId': orgId, 'userId': targetUserId},
    );
    if (existingR.isNotEmpty) {
      final existingRole = existingR.first.toColumnMap()['role'].toString();
      if (existingRole != 'invite_placeholder') {
        _jsonResponse(request, 400, {'error': 'already_member'});
        return;
      }
      await _pool.execute(
        Sql.named('DELETE FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
        parameters: {'orgId': orgId, 'userId': targetUserId},
      );
    }

    final pendingRole = desiredRole == 'super_user' ? 'pending_super_user' : 'pending_member';
    await _pool.execute(
      Sql.named('''
        INSERT INTO organization_users (organization_id, user_id, role, invited_by)
        VALUES (@orgId, @targetUserId, @role, @invitedBy)
      '''),
      parameters: {'orgId': orgId, 'targetUserId': targetUserId, 'role': pendingRole, 'invitedBy': userId},
    );

    final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
    final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';
    final roleLabel = desiredRole == 'super_user' ? 'Super User' : 'Member';

    final locale = await _getUserLocale(targetUserId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, '', 'general', @title, @message)
      '''),
      parameters: {
        'userId': targetUserId,
        'title': _t(locale, 'org_invite_received', {'org': orgName}),
        'message': _t(locale, 'org_invite_received_msg', {'org': orgName, 'role': roleLabel}),
      },
    );

    _jsonResponse(request, 201, {'success': true, 'type': 'email_invite'});
    return;
  }

  final rng = Random.secure();
  final code = List.generate(12, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[rng.nextInt(36)]).join();
  final expiresAt = DateTime.now().add(Duration(days: 7));

  await _pool.execute(
    Sql.named('''
      INSERT INTO organization_users (organization_id, user_id, role, invited_by, invite_code, invite_expires_at)
      VALUES (@orgId, @userId, 'invite_placeholder', @invitedBy, @code, @expires)
      ON CONFLICT DO NOTHING
    '''),
    parameters: {'orgId': orgId, 'userId': userId, 'invitedBy': userId, 'code': code, 'expires': expiresAt.toIso8601String()},
  );

  _jsonResponse(request, 201, {'invite_code': code, 'expires_at': expiresAt.toIso8601String()});
}

Future<void> _getPendingOrgInvites(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final r = await _pool.execute(
    Sql.named('''
      SELECT ou.id, ou.organization_id, ou.role, ou.invited_by, ou.created_at,
             o.name AS organization_name, o.type AS organization_type,
             u.first_name AS inviter_first_name, u.last_name AS inviter_last_name, u.email AS inviter_email
      FROM organization_users ou
      JOIN organizations o ON o.id = ou.organization_id
      LEFT JOIN users u ON u.id = ou.invited_by
      WHERE ou.user_id = @userId AND ou.role IN ('pending_member', 'pending_super_user')
    '''),
    parameters: {'userId': userId},
  );

  final invites = r.map((row) {
    final cols = row.toColumnMap();
    final role = cols['role'].toString();
    return {
      'id': cols['id'].toString(),
      'organization_id': cols['organization_id'].toString(),
      'organization_name': cols['organization_name'].toString(),
      'organization_type': cols['organization_type'].toString(),
      'desired_role': role == 'pending_super_user' ? 'super_user' : 'member',
      'invited_by': cols['invited_by']?.toString() ?? '',
      'inviter_name': '${cols['inviter_first_name'] ?? ''} ${cols['inviter_last_name'] ?? ''}'.trim(),
      'inviter_email': cols['inviter_email']?.toString() ?? '',
      'created_at': cols['created_at']?.toString() ?? '',
    };
  }).toList();

  _jsonResponse(request, 200, invites);
}

Future<void> _acceptOrgInvite(HttpRequest request) async {
  final path = request.uri.path;
  final inviteId = int.parse(path.split('/')[4]);
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final r = await _pool.execute(
    Sql.named('SELECT * FROM organization_users WHERE id = @id AND user_id = @userId AND role IN (\'pending_member\', \'pending_super_user\')'),
    parameters: {'id': inviteId, 'userId': userId},
  );
  if (r.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Invite not found'});
    return;
  }
  final cols = r.first.toColumnMap();
  final orgId = cols['organization_id'] as int;
  final pendingRole = cols['role'].toString();
  final invitedBy = cols['invited_by'];
  final finalRole = pendingRole == 'pending_super_user' ? 'super_user' : 'member';

  await _pool.execute(
    Sql.named('UPDATE organization_users SET role = @role WHERE id = @id'),
    parameters: {'role': finalRole, 'id': inviteId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';
  final userR = await _pool.execute(Sql.named('SELECT first_name, last_name, name FROM users WHERE id = @id'), parameters: {'id': userId});
  final userName = userR.isNotEmpty ? '${userR.first.toColumnMap()['first_name'] ?? ''} ${userR.first.toColumnMap()['last_name'] ?? ''}'.trim() : 'User';
  final displayName = userName.isNotEmpty ? userName : (userR.isNotEmpty ? userR.first.toColumnMap()['name'].toString() : 'User');

  if (invitedBy != null) {
    final inviterId = invitedBy as int;
    final locale = await _getUserLocale(inviterId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, '', 'general', @title, @message)
      '''),
      parameters: {
        'userId': inviterId,
        'title': _t(locale, 'org_invite_accepted', {'member': displayName}),
        'message': _t(locale, 'org_invite_accepted_msg', {'member': displayName, 'org': orgName}),
      },
    );
  }

  _jsonResponse(request, 200, {'success': true, 'organization_id': orgId.toString()});
}

Future<void> _declineOrgInvite(HttpRequest request) async {
  final path = request.uri.path;
  final inviteId = int.parse(path.split('/')[4]);
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final r = await _pool.execute(
    Sql.named('SELECT * FROM organization_users WHERE id = @id AND user_id = @userId AND role IN (\'pending_member\', \'pending_super_user\')'),
    parameters: {'id': inviteId, 'userId': userId},
  );
  if (r.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Invite not found'});
    return;
  }
  final cols = r.first.toColumnMap();
  final orgId = cols['organization_id'] as int;
  final invitedBy = cols['invited_by'];

  await _pool.execute(
    Sql.named('DELETE FROM organization_users WHERE id = @id'),
    parameters: {'id': inviteId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';
  final userR = await _pool.execute(Sql.named('SELECT first_name, last_name, name FROM users WHERE id = @id'), parameters: {'id': userId});
  final userName = userR.isNotEmpty ? '${userR.first.toColumnMap()['first_name'] ?? ''} ${userR.first.toColumnMap()['last_name'] ?? ''}'.trim() : 'User';
  final displayName = userName.isNotEmpty ? userName : (userR.isNotEmpty ? userR.first.toColumnMap()['name'].toString() : 'User');

  if (invitedBy != null) {
    final inviterId = invitedBy as int;
    final locale = await _getUserLocale(inviterId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, '', 'general', @title, @message)
      '''),
      parameters: {
        'userId': inviterId,
        'title': _t(locale, 'org_invite_declined', {'member': displayName}),
        'message': _t(locale, 'org_invite_declined_msg', {'member': displayName, 'org': orgName}),
      },
    );
  }

  _jsonResponse(request, 200, {'success': true});
}

Future<void> _joinOrganization(HttpRequest request) async {
  final path = request.uri.path;
  final code = path.split('/').last;
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final inviteR = await _pool.execute(
    Sql.named('SELECT * FROM organization_users WHERE invite_code = @code'),
    parameters: {'code': code},
  );
  if (inviteR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Invalid invite code'});
    return;
  }
  final inviteCols = inviteR.first.toColumnMap();
  final orgId = inviteCols['organization_id'] as int;
  final expiresAt = inviteCols['invite_expires_at'];
  if (expiresAt != null) {
    final exp = DateTime.parse(expiresAt.toString());
    if (DateTime.now().isAfter(exp)) {
      await _pool.execute(Sql.named('DELETE FROM organization_users WHERE invite_code = @code'), parameters: {'code': code});
      _jsonResponse(request, 400, {'error': 'Invite code has expired'});
      return;
    }
  }

  final existingR = await _pool.execute(
    Sql.named('SELECT id FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (existingR.isNotEmpty) {
    _jsonResponse(request, 400, {'error': 'Already a member of this organization'});
    return;
  }

  final invitedBy = inviteCols['invited_by'] ?? inviteCols['user_id'];

  await _pool.execute(
    Sql.named('''
      INSERT INTO organization_users (organization_id, user_id, role, invited_by)
      VALUES (@orgId, @userId, 'member', @invitedBy)
    '''),
    parameters: {'orgId': orgId, 'userId': userId, 'invitedBy': invitedBy},
  );

  await _pool.execute(Sql.named('DELETE FROM organization_users WHERE invite_code = @code'), parameters: {'code': code});

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';

  final userR = await _pool.execute(Sql.named('SELECT name FROM users WHERE id = @id'), parameters: {'id': userId});
  final userName = userR.isNotEmpty ? userR.first.toColumnMap()['name'].toString() : 'User';

  final superUsers = await _pool.execute(
    Sql.named("SELECT user_id FROM organization_users WHERE organization_id = @orgId AND role = 'super_user'"),
    parameters: {'orgId': orgId},
  );
  for (final su in superUsers) {
    final suId = su.toColumnMap()['user_id'] as int;
    final locale = await _getUserLocale(suId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, '', 'general', @title, @message)
      '''),
      parameters: {
        'userId': suId,
        'title': _t(locale, 'org_member_joined', {'org': orgName}),
        'message': _t(locale, 'org_member_joined_msg', {'member': userName, 'org': orgName}),
      },
    );
  }

  _jsonResponse(request, 200, {'success': true, 'organization_id': orgId.toString()});
}

Future<void> _updateOrgMemberRole(HttpRequest request) async {
  final parts = request.uri.path.split('/');
  final orgId = int.parse(parts[3]);
  final targetUserId = int.parse(parts[5]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final newRole = body['role'] as String? ?? 'member';
  if (newRole != 'super_user' && newRole != 'member') {
    _jsonResponse(request, 400, {'error': 'Role must be super_user or member'});
    return;
  }

  if (newRole == 'member') {
    final suCount = await _pool.execute(
      Sql.named("SELECT COUNT(*) as cnt FROM organization_users WHERE organization_id = @orgId AND role = 'super_user'"),
      parameters: {'orgId': orgId},
    );
    final cnt = suCount.first.toColumnMap()['cnt'] as int;
    if (cnt <= 1) {
      final currentRole = await _pool.execute(
        Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @targetId'),
        parameters: {'orgId': orgId, 'targetId': targetUserId},
      );
      if (currentRole.isNotEmpty && currentRole.first.toColumnMap()['role'].toString() == 'super_user') {
        _jsonResponse(request, 400, {'error': 'Cannot demote the last super user'});
        return;
      }
    }
  }

  await _pool.execute(
    Sql.named('UPDATE organization_users SET role = @role WHERE organization_id = @orgId AND user_id = @targetId'),
    parameters: {'role': newRole, 'orgId': orgId, 'targetId': targetUserId},
  );
  _jsonResponse(request, 200, {'success': true});
}

Future<void> _removeOrgMember(HttpRequest request) async {
  final parts = request.uri.path.split('/');
  final orgId = int.parse(parts[3]);
  final targetUserId = int.parse(parts[5]);
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  if (targetUserId == userId) {
    _jsonResponse(request, 400, {'error': 'Use the leave endpoint to remove yourself'});
    return;
  }

  final targetR = await _pool.execute(
    Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @targetId'),
    parameters: {'orgId': orgId, 'targetId': targetUserId},
  );
  if (targetR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Member not found'});
    return;
  }

  await _pool.execute(
    Sql.named('DELETE FROM organization_users WHERE organization_id = @orgId AND user_id = @targetId'),
    parameters: {'orgId': orgId, 'targetId': targetUserId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';
  final locale = await _getUserLocale(targetUserId);
  final userR = await _pool.execute(Sql.named('SELECT name FROM users WHERE id = @id'), parameters: {'id': targetUserId});
  final memberName = userR.isNotEmpty ? userR.first.toColumnMap()['name'].toString() : 'User';

  await _pool.execute(
    Sql.named('''
      INSERT INTO notifications (user_id, pet_id, type, title, message)
      VALUES (@userId, '', 'general', @title, @message)
    '''),
    parameters: {
      'userId': targetUserId,
      'title': _t(locale, 'org_member_left', {'org': orgName}),
      'message': _t(locale, 'org_member_left_msg', {'member': memberName, 'org': orgName}),
    },
  );

  _jsonResponse(request, 200, {'success': true});
}

Future<void> _leaveOrganization(HttpRequest request) async {
  final parts = request.uri.path.split('/');
  final orgId = int.parse(parts[3]);
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final memberR = await _pool.execute(
    Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Not a member'});
    return;
  }

  if (memberR.first.toColumnMap()['role'].toString() == 'super_user') {
    final suCount = await _pool.execute(
      Sql.named("SELECT COUNT(*) as cnt FROM organization_users WHERE organization_id = @orgId AND role = 'super_user'"),
      parameters: {'orgId': orgId},
    );
    if ((suCount.first.toColumnMap()['cnt'] as int) <= 1) {
      _jsonResponse(request, 400, {'error': 'Cannot leave as the last super user. Promote another member first.'});
      return;
    }
  }

  await _pool.execute(
    Sql.named('DELETE FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';
  final userR = await _pool.execute(Sql.named('SELECT name FROM users WHERE id = @id'), parameters: {'id': userId});
  final memberName = userR.isNotEmpty ? userR.first.toColumnMap()['name'].toString() : 'User';

  final superUsers = await _pool.execute(
    Sql.named("SELECT user_id FROM organization_users WHERE organization_id = @orgId AND role = 'super_user'"),
    parameters: {'orgId': orgId},
  );
  for (final su in superUsers) {
    final suId = su.toColumnMap()['user_id'] as int;
    final locale = await _getUserLocale(suId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, '', 'general', @title, @message)
      '''),
      parameters: {
        'userId': suId,
        'title': _t(locale, 'org_member_left', {'org': orgName}),
        'message': _t(locale, 'org_member_left_msg', {'member': memberName, 'org': orgName}),
      },
    );
  }

  _jsonResponse(request, 200, {'success': true});
}

// ── Organization Pets ────────────────────────────────────────

Future<void> _getOrgPets(HttpRequest request) async {
  final orgId = int.parse(request.uri.path.split('/')[3]);
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return;

  final result = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE organization_id = @orgId ORDER BY created_at'),
    parameters: {'orgId': orgId},
  );
  _jsonResponse(request, 200, result.map(_petRowToJson).toList());
}

Future<void> _createOrgPet(HttpRequest request) async {
  final orgId = int.parse(request.uri.path.split('/')[3]);
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return;
  final userId = member['userId'] as int;

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final id = body['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
  final name = body['name'] as String? ?? '';
  final species = body['species'] as String? ?? '';

  final result = await _pool.execute(
    Sql.named('''
      INSERT INTO pets (id, user_id, organization_id, name, species, breed, weight, gender, bio, insurance, chip_id, color_value, date_of_birth, neutered_date)
      VALUES (@id, @userId, @orgId, @name, @species, @breed, @weight, @gender, @bio, @insurance, @chipId, @colorValue, @dob, @neuteredDate)
      RETURNING *
    '''),
    parameters: {
      'id': id, 'userId': userId, 'orgId': orgId,
      'name': name, 'species': species,
      'breed': body['breed'] as String? ?? '',
      'weight': body['weight'] as num?,
      'gender': body['gender'] as String?,
      'bio': body['bio'] as String? ?? '',
      'insurance': body['insurance'] as String? ?? '',
      'chipId': body['chipId'] as String? ?? body['chip_id'] as String? ?? '',
      'colorValue': body['colorValue'] as int? ?? body['color_value'] as int?,
      'dob': body['dateOfBirth'] as String? ?? body['date_of_birth'] as String?,
      'neuteredDate': body['neuteredDate'] as String? ?? body['neutered_date'] as String?,
    },
  );
  _jsonResponse(request, 201, _petRowToJson(result.first));
}

// ── Transfer: Org → User ─────────────────────────────────────

Future<void> _transferOrgPet(HttpRequest request) async {
  final parts = request.uri.path.split('/');
  final orgId = int.parse(parts[3]);
  final petId = parts[5];
  final userId = await _requireOrgSuperUser(request, orgId);
  if (userId == null) return;

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final recipientEmail = (body['recipient_email'] as String?)?.trim().toLowerCase() ?? '';
  final transferType = body['transfer_type'] as String? ?? 'adoption';
  final notes = body['notes'] as String? ?? '';

  if (recipientEmail.isEmpty) {
    _jsonResponse(request, 400, {'error': 'Recipient email is required'});
    return;
  }

  final recipientR = await _pool.execute(
    Sql.named('SELECT id, name FROM users WHERE LOWER(email) = @email'),
    parameters: {'email': recipientEmail},
  );
  if (recipientR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Recipient user not found. They must have an account.'});
    return;
  }
  final recipientId = recipientR.first.toColumnMap()['id'] as int;
  final recipientName = recipientR.first.toColumnMap()['name'].toString();

  final petR = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE id = @id AND organization_id = @orgId'),
    parameters: {'id': petId, 'orgId': orgId},
  );
  if (petR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Pet not found in this organization'});
    return;
  }
  final pet = _petRowToJson(petR.first);
  final petName = pet['name'] ?? '';

  await _pool.execute(
    Sql.named('''
      INSERT INTO archived_pets (organization_id, pet_id, pet_name, species, transfer_type, transferred_to_user_id, notes)
      VALUES (@orgId, @petId, @petName, @species, @transferType, @recipientId, @notes)
    '''),
    parameters: {
      'orgId': orgId, 'petId': petId, 'petName': petName,
      'species': pet['species'] ?? '', 'transferType': transferType,
      'recipientId': recipientId, 'notes': notes,
    },
  );

  await _pool.execute(
    Sql.named('UPDATE pets SET organization_id = NULL, user_id = @recipientId, updated_at = NOW() WHERE id = @petId'),
    parameters: {'recipientId': recipientId, 'petId': petId},
  );

  await _pool.execute(
    Sql.named('DELETE FROM pet_access WHERE pet_id = @petId'),
    parameters: {'petId': petId},
  );
  await _pool.execute(
    Sql.named('''
      INSERT INTO pet_access (pet_id, user_id, role)
      VALUES (@petId, @recipientId, 'guardian')
      ON CONFLICT (pet_id, user_id) DO UPDATE SET role = 'guardian'
    '''),
    parameters: {'petId': petId, 'recipientId': recipientId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';

  final recipientLocale = await _getUserLocale(recipientId);
  await _pool.execute(
    Sql.named('''
      INSERT INTO notifications (user_id, pet_id, type, title, message)
      VALUES (@userId, @petId, 'general', @title, @message)
    '''),
    parameters: {
      'userId': recipientId, 'petId': petId,
      'title': _t(recipientLocale, 'org_pet_received', {'pet': petName}),
      'message': _t(recipientLocale, 'org_pet_received_msg', {'pet': petName, 'org': orgName}),
    },
  );

  final orgMembers = await _pool.execute(
    Sql.named('SELECT user_id FROM organization_users WHERE organization_id = @orgId'),
    parameters: {'orgId': orgId},
  );
  for (final m in orgMembers) {
    final mId = m.toColumnMap()['user_id'] as int;
    final locale = await _getUserLocale(mId);
    await _pool.execute(
      Sql.named('''
        INSERT INTO notifications (user_id, pet_id, type, title, message)
        VALUES (@userId, @petId, 'general', @title, @message)
      '''),
      parameters: {
        'userId': mId, 'petId': petId,
        'title': _t(locale, 'org_pet_transferred_out', {'pet': petName}),
        'message': _t(locale, 'org_pet_transferred_out_msg', {'pet': petName, 'recipient': recipientName}),
      },
    );
  }

  _jsonResponse(request, 200, {'success': true, 'pet_id': petId});
}

// ── Transfer: User → Org ─────────────────────────────────────

Future<void> _transferPetToOrg(HttpRequest request) async {
  final path = request.uri.path;
  final petId = path.split('/')[3];
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }

  final accessR = await _pool.execute(
    Sql.named("SELECT role FROM pet_access WHERE pet_id = @petId AND user_id = @userId AND role = 'guardian'"),
    parameters: {'petId': petId, 'userId': userId},
  );
  if (accessR.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Only guardians can transfer pets'});
    return;
  }

  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final orgId = int.tryParse((body['organization_id'] ?? '').toString());
  final transferType = body['transfer_type'] as String? ?? 'transfer';
  final notes = body['notes'] as String? ?? '';

  if (orgId == null) {
    _jsonResponse(request, 400, {'error': 'Organization ID is required'});
    return;
  }

  final memberCheck = await _pool.execute(
    Sql.named('SELECT role FROM organization_users WHERE organization_id = @orgId AND user_id = @userId'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberCheck.isEmpty) {
    _jsonResponse(request, 403, {'error': 'You must be a member of the organization'});
    return;
  }

  final petR = await _pool.execute(
    Sql.named('SELECT * FROM pets WHERE id = @id AND user_id = @userId AND organization_id IS NULL'),
    parameters: {'id': petId, 'userId': userId},
  );
  if (petR.isEmpty) {
    _jsonResponse(request, 404, {'error': 'Pet not found or already belongs to an organization'});
    return;
  }
  final pet = _petRowToJson(petR.first);
  final petName = pet['name'] ?? '';

  await _pool.execute(
    Sql.named('''
      INSERT INTO archived_pets (user_id, pet_id, pet_name, species, transfer_type, transferred_to_org_id, notes)
      VALUES (@userId, @petId, @petName, @species, @transferType, @orgId, @notes)
    '''),
    parameters: {
      'userId': userId, 'petId': petId, 'petName': petName,
      'species': pet['species'] ?? '', 'transferType': transferType,
      'orgId': orgId, 'notes': notes,
    },
  );

  await _pool.execute(
    Sql.named('UPDATE pets SET organization_id = @orgId, updated_at = NOW() WHERE id = @petId'),
    parameters: {'orgId': orgId, 'petId': petId},
  );

  await _pool.execute(
    Sql.named('DELETE FROM pet_access WHERE pet_id = @petId'),
    parameters: {'petId': petId},
  );

  final orgR = await _pool.execute(Sql.named('SELECT name FROM organizations WHERE id = @id'), parameters: {'id': orgId});
  final orgName = orgR.isNotEmpty ? orgR.first.toColumnMap()['name'].toString() : 'Organization';

  final locale = await _getUserLocale(userId);
  await _pool.execute(
    Sql.named('''
      INSERT INTO notifications (user_id, pet_id, type, title, message)
      VALUES (@userId, @petId, 'general', @title, @message)
    '''),
    parameters: {
      'userId': userId, 'petId': petId,
      'title': _t(locale, 'org_pet_donated', {'pet': petName, 'org': orgName}),
      'message': _t(locale, 'org_pet_donated_msg', {'pet': petName, 'org': orgName}),
    },
  );

  _jsonResponse(request, 200, {'success': true, 'pet_id': petId});
}

// ── Archived Pets ────────────────────────────────────────────

Future<void> _getOrgArchivedPets(HttpRequest request) async {
  final orgId = int.parse(request.uri.path.split('/')[3]);
  final member = await _requireOrgMember(request, orgId);
  if (member == null) return;

  final result = await _pool.execute(
    Sql.named('SELECT * FROM archived_pets WHERE organization_id = @orgId ORDER BY archived_at DESC'),
    parameters: {'orgId': orgId},
  );
  _jsonResponse(request, 200, result.map(_archivedPetToJson).toList());
}

Future<void> _getUserArchivedPets(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final result = await _pool.execute(
    Sql.named('SELECT * FROM archived_pets WHERE user_id = @userId ORDER BY archived_at DESC'),
    parameters: {'userId': userId},
  );
  _jsonResponse(request, 200, result.map(_archivedPetToJson).toList());
}

Map<String, dynamic> _archivedPetToJson(ResultRow row) {
  final cols = row.toColumnMap();
  return {
    'id': cols['id'].toString(),
    'organization_id': cols['organization_id']?.toString(),
    'user_id': cols['user_id']?.toString(),
    'pet_id': cols['pet_id'].toString(),
    'pet_name': (cols['pet_name'] ?? '').toString(),
    'species': (cols['species'] ?? '').toString(),
    'pdf_data': (cols['pdf_data'] ?? '').toString(),
    'transfer_type': (cols['transfer_type'] ?? 'other').toString(),
    'transferred_to_user_id': cols['transferred_to_user_id']?.toString(),
    'transferred_to_org_id': cols['transferred_to_org_id']?.toString(),
    'notes': (cols['notes'] ?? '').toString(),
    'archived_at': cols['archived_at']?.toString(),
    'created_at': cols['created_at']?.toString(),
  };
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

// ── Family Events CRUD ───────────────────────────────────────

Future<void> _getFamilyEvents(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final petId = request.uri.path.split('/')[3];
  final pet = await _pool.execute(
    Sql.named('SELECT organization_id FROM pets WHERE id = @petId'),
    parameters: {'petId': petId},
  );
  if (pet.isEmpty || pet.first.toColumnMap()['organization_id'] == null) {
    _jsonResponse(request, 400, {'error': 'Pet is not in an organization'});
    return;
  }
  final orgId = pet.first.toColumnMap()['organization_id'] as int;
  final memberCheck = await _pool.execute(
    Sql.named('SELECT id FROM organization_users WHERE organization_id = @orgId AND user_id = @userId AND role IN (\'super_user\', \'member\')'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberCheck.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Not a member of this organization'});
    return;
  }
  final rows = await _pool.execute(
    Sql.named('''
      SELECT fe.*, u.first_name, u.last_name, u.email AS assigned_email
      FROM family_events fe
      LEFT JOIN users u ON fe.assigned_to_user_id = u.id
      WHERE fe.pet_id = @petId
      ORDER BY fe.from_date DESC
    '''),
    parameters: {'petId': petId},
  );
  final events = rows.map((r) {
    final c = r.toColumnMap();
    final firstName = (c['first_name'] ?? '').toString();
    final lastName = (c['last_name'] ?? '').toString();
    final assignedName = '$firstName $lastName'.trim();
    return {
      'id': c['id'],
      'pet_id': c['pet_id'].toString(),
      'organization_id': c['organization_id'],
      'assigned_to_user_id': c['assigned_to_user_id'],
      'assigned_name': assignedName,
      'assigned_email': (c['assigned_email'] ?? '').toString(),
      'from_date': c['from_date']?.toString(),
      'to_date': c['to_date']?.toString(),
      'notes': (c['notes'] ?? '').toString(),
      'created_by': c['created_by'],
      'created_at': c['created_at']?.toString(),
    };
  }).toList();
  _jsonResponse(request, 200, events);
}

Future<void> _createFamilyEvent(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final petId = request.uri.path.split('/')[3];
  final pet = await _pool.execute(
    Sql.named('SELECT organization_id FROM pets WHERE id = @petId'),
    parameters: {'petId': petId},
  );
  if (pet.isEmpty || pet.first.toColumnMap()['organization_id'] == null) {
    _jsonResponse(request, 400, {'error': 'Pet is not in an organization'});
    return;
  }
  final orgId = pet.first.toColumnMap()['organization_id'] as int;
  final memberCheck = await _pool.execute(
    Sql.named('SELECT id FROM organization_users WHERE organization_id = @orgId AND user_id = @userId AND role IN (\'super_user\', \'member\')'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberCheck.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Not a member of this organization'});
    return;
  }
  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final assignedTo = body['assigned_to_user_id'] != null ? int.tryParse(body['assigned_to_user_id'].toString()) : null;
  final fromDate = body['from_date'] as String?;
  final toDate = body['to_date'] as String?;
  final notes = (body['notes'] ?? '').toString();
  if (fromDate == null) {
    _jsonResponse(request, 400, {'error': 'from_date is required'});
    return;
  }
  final result = await _pool.execute(
    Sql.named('''
      INSERT INTO family_events (pet_id, organization_id, assigned_to_user_id, from_date, to_date, notes, created_by)
      VALUES (@petId, @orgId, ${assignedTo != null ? '@assignedTo' : 'NULL'}, @fromDate::date, ${toDate != null ? '@toDate::date' : 'NULL'}, @notes, @userId)
      RETURNING *
    '''),
    parameters: {
      'petId': petId, 'orgId': orgId,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
      'notes': notes, 'userId': userId,
    },
  );
  final c = result.first.toColumnMap();
  _jsonResponse(request, 201, {
    'id': c['id'],
    'pet_id': c['pet_id'].toString(),
    'organization_id': c['organization_id'],
    'assigned_to_user_id': c['assigned_to_user_id'],
    'from_date': c['from_date']?.toString(),
    'to_date': c['to_date']?.toString(),
    'notes': (c['notes'] ?? '').toString(),
    'created_by': c['created_by'],
    'created_at': c['created_at']?.toString(),
  });
}

Future<void> _updateFamilyEvent(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final parts = request.uri.path.split('/');
  final petId = parts[3];
  final eventId = int.parse(parts[5]);
  final pet = await _pool.execute(
    Sql.named('SELECT organization_id FROM pets WHERE id = @petId'),
    parameters: {'petId': petId},
  );
  if (pet.isEmpty || pet.first.toColumnMap()['organization_id'] == null) {
    _jsonResponse(request, 400, {'error': 'Pet is not in an organization'});
    return;
  }
  final orgId = pet.first.toColumnMap()['organization_id'] as int;
  final memberCheck = await _pool.execute(
    Sql.named('SELECT id FROM organization_users WHERE organization_id = @orgId AND user_id = @userId AND role IN (\'super_user\', \'member\')'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberCheck.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Not a member'});
    return;
  }
  final body = json.decode(await utf8.decodeStream(request)) as Map<String, dynamic>;
  final assignedTo = body['assigned_to_user_id'] != null ? int.tryParse(body['assigned_to_user_id'].toString()) : null;
  final fromDate = body['from_date'] as String?;
  final toDate = body['to_date'] as String?;
  final notes = (body['notes'] ?? '').toString();
  await _pool.execute(
    Sql.named('''
      UPDATE family_events SET
        assigned_to_user_id = ${assignedTo != null ? '@assignedTo' : 'NULL'},
        from_date = ${fromDate != null ? '@fromDate::date' : 'from_date'},
        to_date = ${toDate != null ? '@toDate::date' : 'NULL'},
        notes = @notes,
        updated_at = NOW()
      WHERE id = @eventId AND pet_id = @petId
    '''),
    parameters: {
      'eventId': eventId, 'petId': petId,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (fromDate != null) 'fromDate': fromDate,
      if (toDate != null) 'toDate': toDate,
      'notes': notes,
    },
  );
  _jsonResponse(request, 200, {'success': true});
}

Future<void> _deleteFamilyEvent(HttpRequest request) async {
  final userId = _getUserIdFromRequest(request);
  if (userId == null) {
    _jsonResponse(request, 401, {'error': 'Authentication required'});
    return;
  }
  final parts = request.uri.path.split('/');
  final petId = parts[3];
  final eventId = int.parse(parts[5]);
  final pet = await _pool.execute(
    Sql.named('SELECT organization_id FROM pets WHERE id = @petId'),
    parameters: {'petId': petId},
  );
  if (pet.isEmpty || pet.first.toColumnMap()['organization_id'] == null) {
    _jsonResponse(request, 400, {'error': 'Pet is not in an organization'});
    return;
  }
  final orgId = pet.first.toColumnMap()['organization_id'] as int;
  final memberCheck = await _pool.execute(
    Sql.named('SELECT id FROM organization_users WHERE organization_id = @orgId AND user_id = @userId AND role IN (\'super_user\', \'member\')'),
    parameters: {'orgId': orgId, 'userId': userId},
  );
  if (memberCheck.isEmpty) {
    _jsonResponse(request, 403, {'error': 'Not a member'});
    return;
  }
  await _pool.execute(
    Sql.named('DELETE FROM family_events WHERE id = @eventId AND pet_id = @petId'),
    parameters: {'eventId': eventId, 'petId': petId},
  );
  _jsonResponse(request, 200, {'success': true});
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
