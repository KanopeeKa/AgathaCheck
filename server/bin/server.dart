import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../lib/routes.dart';

void main() async {
  // Create the router
  final router = apiHandler();

  // Add CORS middleware
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router);

  // Start the server
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server listening on port ${server.port}');
}