import 'package:postgres/postgres.dart';
import 'package:shelf_router/shelf_router.dart';

import 'core_routes.dart';
import 'invites_routes.dart';
import 'members_routes.dart';
import 'pets_routes.dart';

Router organizationRoutes(Pool pool) {
  final router = Router();
  registerOrgInvitesRoutes(router, pool);
  registerOrgCoreRoutes(router, pool);
  registerOrgMembersRoutes(router, pool);
  registerOrgPetsRoutes(router, pool);
  return router;
}
