import 'package:postgres/postgres.dart';
import 'package:shelf_router/shelf_router.dart';

import 'placements/placements_action_routes.dart';
import 'placements/placements_create_routes.dart';
import 'placements/placements_query_routes.dart';

void registerOrgPlacementsRoutes(Router router, Pool pool) {
  registerOrgPlacementsQueryRoutes(router, pool);
  registerOrgPlacementsCreateRoutes(router, pool);
  registerOrgPlacementsActionRoutes(router, pool);
}
