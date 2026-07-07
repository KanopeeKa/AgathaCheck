import 'package:postgres/postgres.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth/password_routes.dart';
import 'auth/profile_routes.dart';
import 'auth/session_routes.dart';

Router authRoutes(Pool pool) {
  final router = Router();
  registerSessionRoutes(router, pool);
  registerProfileRoutes(router, pool);
  registerPasswordRoutes(router, pool);
  return router;
}
