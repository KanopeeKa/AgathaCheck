import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

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
      await pool.execute(Sql(sql));
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
      default:
        print('Usage: dart run bin/migrate.dart [up|down|status]');
    }
  } finally {
    await pool.close();
  }
}
