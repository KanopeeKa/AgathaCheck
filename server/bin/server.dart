import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import '../lib/routes.dart';
import '../lib/auth_routes.dart' as auth;

void main() async {
  await initPool();

  final petRouter = apiHandler();
  final authRouter = auth.authRoutes(pool);

  final topRouter = Router();
  topRouter.mount('/api/auth/', authRouter.call);
  topRouter.mount('/backend/api/auth/', authRouter.call);

  final webDir = Platform.environment['FLUTTER_WEB_DIR'] ??
      '${Directory.current.parent.path}/flutter_app/build/web';

  Handler fallbackHandler;
  if (Directory(webDir).existsSync()) {
    final staticHandler = createStaticHandler(webDir, defaultDocument: 'index.html');
    fallbackHandler = staticHandler;
  } else {
    fallbackHandler = (Request request) => Response.notFound('Web build not found');
  }

  Middleware allowIframe() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'X-Frame-Options': 'ALLOWALL',
          ...response.headersAll.containsKey('content-security-policy')
              ? {}
              : {'Content-Security-Policy': 'frame-ancestors *'},
        });
      };
    };
  }

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(allowIframe())
      .addHandler((Request request) async {
    final path = request.url.path;
    if (path.startsWith('api/auth/') || path.startsWith('backend/api/auth/')) {
      return topRouter.call(request);
    }
    if (path.startsWith('api/') || path.startsWith('backend/')) {
      return petRouter.call(request);
    }
    if (path.startsWith('uploads/')) {
      final file = File(path);
      if (file.existsSync()) {
        return Response.ok(file.readAsBytesSync(),
            headers: {'Content-Type': 'image/jpeg'});
      }
      return Response.notFound('File not found');
    }
    return fallbackHandler(request);
  });

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('Server listening on port ${server.port}');
  print('Serving Flutter web from: $webDir');
}
