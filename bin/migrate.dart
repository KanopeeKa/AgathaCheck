import 'dart:io';
import 'package:postgres/postgres.dart';

late Pool _pool;

(Endpoint, SslMode) _parseDbUrl(String url) {
  final uri = Uri.parse(url);
  final host = uri.host.isNotEmpty ? uri.host : 'localhost';
  final port = uri.port != 0 ? uri.port : 5432;
  final database =
      uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'postgres';
  final username = uri.userInfo.contains(':')
      ? uri.userInfo.split(':').first
      : (uri.userInfo.isNotEmpty ? uri.userInfo : 'postgres');
  final password =
      uri.userInfo.contains(':') ? uri.userInfo.split(':').last : '';

  final needsSsl =
      url.contains('neon.tech') || url.contains('sslmode=require');
  final sslMode = needsSsl ? SslMode.require : SslMode.disable;

  final endpoint = Endpoint(
    host: host,
    port: port,
    database: database,
    username: username,
    password: password,
  );

  return (endpoint, sslMode);
}

Future<void> main(List<String> args) async {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null || dbUrl.isEmpty) {
    print('Error: DATABASE_URL environment variable is not set.');
    exit(1);
  }

  final direction = args.isNotEmpty ? args.first : 'up';
  if (direction != 'up' && direction != 'down') {
    print('Usage: dart run bin/migrate.dart [up|down]');
    exit(1);
  }

  final (endpoint, sslMode) = _parseDbUrl(dbUrl);

  _pool = Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(maxConnectionCount: 2, sslMode: sslMode),
  );

  print('Connected to database at ${endpoint.host}:${endpoint.port}/${endpoint.database}');

  final migrationsDir = Directory('db/migrations');
  if (!migrationsDir.existsSync()) {
    print('Error: db/migrations/ directory not found.');
    exit(1);
  }

  if (direction == 'up') {
    await _runUp(migrationsDir);
  } else {
    await _runDown(migrationsDir);
  }

  await _pool.close();
  print('Done.');
}

Future<void> _runUp(Directory dir) async {
  await _pool.execute(Sql('''
    CREATE TABLE IF NOT EXISTS _migrations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMPTZ DEFAULT NOW()
    )
  '''));

  final appliedResult = await _pool.execute(
    Sql('SELECT name FROM _migrations ORDER BY name'),
  );
  final applied = appliedResult.map((r) => r[0] as String).toSet();

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.sql') && !f.path.endsWith('_down.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var count = 0;
  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.sql', '');
    if (applied.contains(name)) {
      print('  SKIP  $name (already applied)');
      continue;
    }

    print('  APPLY $name ...');
    final sql = file.readAsStringSync();
    final statements = _splitStatements(sql);
    for (final stmt in statements) {
      await _pool.execute(Sql(stmt));
    }
    await _pool.execute(
      Sql("INSERT INTO _migrations (name) VALUES (\$1)"),
      parameters: [name],
    );
    count++;
  }

  if (count == 0) {
    print('All migrations are up to date.');
  } else {
    print('Applied $count migration(s).');
  }
}

Future<void> _runDown(Directory dir) async {
  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('_down.sql'))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));

  if (files.isEmpty) {
    print('No down migrations found.');
    return;
  }

  print('WARNING: This will drop tables and delete all data.');
  print('Running ${files.length} down migration(s)...');

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    print('  APPLY $name ...');
    final sql = file.readAsStringSync();
    final statements = _splitStatements(sql);
    for (final stmt in statements) {
      await _pool.execute(Sql(stmt));
    }
  }

  await _pool.execute(Sql('DROP TABLE IF EXISTS _migrations'));
  print('All down migrations applied.');
}

List<String> _splitStatements(String sql) {
  final statements = <String>[];
  final buffer = StringBuffer();
  var inDollarQuote = false;
  var dollarTag = '';

  final lines = sql.split('\n');
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('--') || trimmed.isEmpty) continue;

    if (inDollarQuote) {
      buffer.writeln(line);
      if (trimmed.contains(dollarTag)) {
        inDollarQuote = false;
      }
      continue;
    }

    final dollarMatch = RegExp(r'\$[a-zA-Z_]*\$').firstMatch(trimmed);
    if (dollarMatch != null) {
      inDollarQuote = true;
      dollarTag = dollarMatch.group(0)!;
      buffer.writeln(line);
      continue;
    }

    if (trimmed.endsWith(';')) {
      buffer.write(trimmed.substring(0, trimmed.length - 1));
      final stmt = buffer.toString().trim();
      if (stmt.isNotEmpty) statements.add(stmt);
      buffer.clear();
    } else {
      buffer.writeln(line);
    }
  }

  final remaining = buffer.toString().trim();
  if (remaining.isNotEmpty) {
    final cleaned = remaining.endsWith(';')
        ? remaining.substring(0, remaining.length - 1).trim()
        : remaining;
    if (cleaned.isNotEmpty) statements.add(cleaned);
  }

  return statements;
}
