import 'dart:io';

import 'package:postgres/postgres.dart';

late Pool _pool;
Pool get pool => _pool;

Future<void> initPool() async {
  final databaseUrl = Platform.environment['DATABASE_URL'] ??
      'postgresql://user:password@localhost:5432/agatha_db';
  final uri = Uri.parse(databaseUrl);
  final host = uri.host.isNotEmpty
      ? uri.host
      : (Platform.environment['PGHOST'] ?? 'localhost');
  final port = uri.port > 0
      ? uri.port
      : int.parse(Platform.environment['PGPORT'] ?? '5432');
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

  _pool = Pool.withEndpoints(
    [endpoint],
    settings: PoolSettings(
      maxConnectionCount: 10,
      sslMode: sslMode,
    ),
  );
}
