import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import 'migrations/016_migrate_family_events_placements.dart';

final _uuid = Uuid();

Future<Pool> _createPool() async {
  final databaseUrl = Platform.environment['DATABASE_URL'] ??
      'postgresql://user:password@localhost:5432/agatha_db';
  final uri = Uri.parse(databaseUrl);
  final host = uri.host.isNotEmpty
      ? uri.host
      : (Platform.environment['PGHOST'] ?? 'localhost');
  final port =
      uri.port > 0 ? uri.port : int.parse(Platform.environment['PGPORT'] ?? '5432');
  final dbName = uri.pathSegments.isNotEmpty
      ? uri.pathSegments.first
      : (Platform.environment['PGDATABASE'] ?? 'agatha_db');
  final userInfo = uri.userInfo.isNotEmpty ? uri.userInfo : '';
  final username = userInfo.contains(':')
      ? userInfo.split(':').first
      : (Platform.environment['PGUSER'] ?? 'user');
  final password = userInfo.contains(':')
      ? userInfo.split(':').last
      : (Platform.environment['PGPASSWORD'] ?? 'password');

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: dbName,
    username: username,
    password: password,
  );

  final sslMode =
      uri.scheme == 'postgresqls' ? SslMode.require : SslMode.disable;

  return Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(maxConnectionCount: 2, sslMode: sslMode),
  );
}

Future<void> _ensureMigrationsTable(Pool pool) async {
  await pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS _migrations (
      id UUID PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      applied_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));
}

Future<Set<String>> _appliedMigrations(Pool pool) async {
  final rows = await pool.execute(Sql('SELECT name FROM _migrations'));
  return rows.map((r) => r[0] as String).toSet();
}

List<FileSystemEntity> _migrationFiles() {
  final script = Platform.script.toFilePath();
  final serverDir = File(script).parent.parent.path;
  final projectRoot = Directory(serverDir).parent.path;
  final dir = Directory('$projectRoot/db/migrations');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    return [];
  }
  final files = dir
      .listSync()
      .where((f) =>
          f is File &&
          f.path.endsWith('.sql') &&
          !f.path.contains('_down'))
      .toList()
    ..sort((a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last));
  return files;
}

Future<void> _applyMigration(Pool pool, String name, String sql) async {
  switch (name) {
    case '016_migrate_family_events_placements.sql':
      await migrateFamilyEventsPlacements(pool);
      return;
    default:
      await pool.execute(Sql(sql));
  }
}

Future<void> _runUp(Pool pool) async {
  await _ensureMigrationsTable(pool);
  final applied = await _appliedMigrations(pool);
  final files = _migrationFiles();
  var ran = 0;

  for (final f in files) {
    final name = f.uri.pathSegments.last;
    if (applied.contains(name)) {
      print('  skip  $name (already applied)');
      continue;
    }
    final sql = File(f.path).readAsStringSync();
    print('  apply $name ...');
    try {
      await _applyMigration(pool, name, sql);
      await pool.execute(
        Sql.named(
            'INSERT INTO _migrations (id, name) VALUES (@id, @name)'),
        parameters: {'id': _uuid.v4(), 'name': name},
      );
      ran++;
      print('  done  $name');
    } catch (e) {
      print('  FAIL  $name: $e');
      rethrow;
    }
  }

  if (ran == 0) {
    print('Nothing to migrate — all migrations already applied.');
  } else {
    print('Applied $ran migration(s).');
  }
}

Future<void> _runDown(Pool pool) async {
  await _ensureMigrationsTable(pool);
  final applied = await _appliedMigrations(pool);
  if (applied.isEmpty) {
    print('No migrations to roll back.');
    return;
  }
  final sorted = applied.toList()..sort();
  final last = sorted.last;
  final downName = last.replaceAll('.sql', '_down.sql');
  final script = Platform.script.toFilePath();
  final serverDir = File(script).parent.parent.path;
  final projectRoot = Directory(serverDir).parent.path;
  final downFile = File('$projectRoot/db/migrations/$downName');
  if (!downFile.existsSync()) {
    print('No down migration found for $last ($downName)');
    return;
  }
  final sql = downFile.readAsStringSync();
  print('  rollback $last ...');
  await pool.execute(Sql(sql));
  await pool.execute(
    Sql.named('DELETE FROM _migrations WHERE name = @name'),
    parameters: {'name': last},
  );
  print('  done');
}

Future<void> _runFresh(Pool pool) async {
  if (Platform.environment['MIGRATE_CONFIRM'] != 'DROP_ALL') {
    print('REFUSED: `fresh` drops every table in the current database.');
    print('Re-run with the explicit confirmation env var:');
    print('  MIGRATE_CONFIRM=DROP_ALL dart run bin/migrate.dart fresh');
    exitCode = 2;
    return;
  }

  final script = Platform.script.toFilePath();
  final serverDir = File(script).parent.parent.path;
  final projectRoot = Directory(serverDir).parent.path;
  final v3File =
      File('$projectRoot/db/migrations/v3__initial_uuid_schema.sql');
  if (!v3File.existsSync()) {
    print('FAIL: canonical schema not found at ${v3File.path}');
    exitCode = 1;
    return;
  }

  print('  drop  public schema (cascade) ...');
  await pool.execute(Sql('DROP SCHEMA IF EXISTS public CASCADE'));
  await pool.execute(Sql('CREATE SCHEMA public'));
  print('  done  schema dropped');

  print('  apply v3__initial_uuid_schema.sql (canonical) ...');
  await pool.execute(Sql(v3File.readAsStringSync()));
  print('  done  schema created');

  // Mark every NNN_*.sql migration as already applied — the canonical v3
  // schema inlines them, so up() must not try to re-run them.
  await _ensureMigrationsTable(pool);
  final incremental = _migrationFiles().where((f) {
    final name = f.uri.pathSegments.last;
    return !name.startsWith('v3');
  });
  for (final f in incremental) {
    final name = f.uri.pathSegments.last;
    await pool.execute(
      Sql.named('INSERT INTO _migrations (id, name) VALUES (@id, @name)'),
      parameters: {'id': _uuid.v4(), 'name': name},
    );
    print('  mark  $name as applied');
  }

  print('\nFresh install complete.');
  print('Database now matches the canonical v3 schema.');
}

Future<void> _showStatus(Pool pool) async {
  await _ensureMigrationsTable(pool);
  final applied = await _appliedMigrations(pool);
  final files = _migrationFiles();

  print('Migration status:');
  for (final f in files) {
    final name = f.uri.pathSegments.last;
    final status = applied.contains(name) ? 'applied' : 'PENDING';
    print('  [$status] $name');
  }
  final pending =
      files.where((f) => !applied.contains(f.uri.pathSegments.last)).length;
  print('${applied.length} applied, $pending pending.');
}

Future<void> main(List<String> args) async {
  final command = args.isNotEmpty ? args[0] : 'up';
  print('Agatha Track — Migration Runner');
  print('Command: $command\n');

  final pool = await _createPool();
  try {
    switch (command) {
      case 'up':
        await _runUp(pool);
        break;
      case 'down':
        await _runDown(pool);
        break;
      case 'status':
        await _showStatus(pool);
        break;
      case 'fresh':
        await _runFresh(pool);
        break;
      default:
        print('Usage: dart run bin/migrate.dart [up|down|status|fresh]');
        print('');
        print('  up      apply pending NNN_*.sql migrations');
        print('  down    roll back the most recently applied migration');
        print('  status  show which migrations are applied/pending');
        print('  fresh   DROP every table and recreate from the canonical');
        print('          v3 schema. Requires MIGRATE_CONFIRM=DROP_ALL.');
    }
  } finally {
    await pool.close();
  }
}
