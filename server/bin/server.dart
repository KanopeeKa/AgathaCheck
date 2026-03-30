import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_static/shelf_static.dart';
import '../lib/routes.dart';
import '../lib/auth_routes.dart' as auth;
import '../lib/sharing_routes.dart' as sharing;
import '../lib/vet_routes.dart' as vets;
import '../lib/health_routes.dart' as health;
import '../lib/health_issue_routes.dart' as healthIssues;
import '../lib/notification_routes.dart' as notifications;
import '../lib/organization_routes.dart' as orgs;
import '../lib/weight_routes.dart' as weight;

void main() async {
  await initPool();

  final petRouter = apiHandler();
  final authRouter = auth.authRoutes(pool);
  final shareRouter = sharing.sharingRoutes(pool);
  final vetRouter = vets.vetRoutes(pool);
  final healthRouter = health.healthRoutes(pool);
  final healthIssueRouter = healthIssues.healthIssueRoutes(pool);
  final notificationRouter = notifications.notificationRoutes(pool);
  final orgRouter = orgs.organizationRoutes(pool);
  final weightRouter = weight.weightRoutes(pool);

  final topRouter = Router();
  topRouter.mount('/api/auth/', authRouter.call);
  topRouter.mount('/backend/api/auth/', authRouter.call);
  topRouter.mount('/api/share/', shareRouter.call);
  topRouter.mount('/backend/api/share/', shareRouter.call);
  topRouter.mount('/api/vets/', vetRouter.call);
  topRouter.mount('/backend/api/vets/', vetRouter.call);
  topRouter.mount('/api/health-entries/', healthRouter.call);
  topRouter.mount('/backend/api/health-entries/', healthRouter.call);
  topRouter.mount('/api/health-issues/', healthIssueRouter.call);
  topRouter.mount('/backend/api/health-issues/', healthIssueRouter.call);
  topRouter.mount('/api/notifications/', notificationRouter.call);
  topRouter.mount('/backend/api/notifications/', notificationRouter.call);
  topRouter.mount('/api/organizations/', orgRouter.call);
  topRouter.mount('/backend/api/organizations/', orgRouter.call);
  topRouter.mount('/api/weight-entries/', weightRouter.call);
  topRouter.mount('/backend/api/weight-entries/', weightRouter.call);
  topRouter.mount('/api/', petRouter.call);
  topRouter.mount('/backend/api/', petRouter.call);

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

  Middleware normalizeTrailingSlash() {
    final mountedPrefixes = {
      'api/health-entries', 'api/health-issues', 'api/notifications',
      'api/organizations', 'api/weight-entries', 'api/auth', 'api/share',
      'api/vets', 'backend/api/health-entries', 'backend/api/health-issues',
      'backend/api/notifications', 'backend/api/organizations',
      'backend/api/weight-entries', 'backend/api/auth', 'backend/api/share',
      'backend/api/vets',
    };
    return (Handler innerHandler) {
      return (Request request) {
        final path = request.url.path;
        if (mountedPrefixes.contains(path)) {
          final newUri = request.requestedUri.replace(path: '${request.requestedUri.path}/');
          final newRequest = Request(request.method, newUri, headers: request.headers, body: request.read(), context: request.context);
          return innerHandler(newRequest);
        }
        return innerHandler(request);
      };
    };
  }

  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(allowIframe())
      .addMiddleware(normalizeTrailingSlash())
      .addHandler((Request request) async {
    final path = request.url.path;
    if (path.startsWith('api/') || path.startsWith('backend/')) {
      return topRouter.call(request);
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
