import 'package:go_router/go_router.dart';

/// Redirect routes for frozen Shelter/Fostering domains (no organization imports).
List<RouteBase> buildFrozenDomainRedirectRoutes() {
  return [
    GoRoute(
      path: '/o/:rest(.*)',
      redirect: (context, state) => '/pc/home',
    ),
    GoRoute(
      path: '/organizations',
      redirect: (context, state) => '/pc/home',
    ),
    GoRoute(
      path: '/organizations/:tail(.*)',
      redirect: (context, state) => '/pc/home',
    ),
    GoRoute(
      path: '/archived-pets',
      redirect: (context, state) => '/pc/home',
    ),
  ];
}

/// Frozen MVP: public org profiles are not served.
bool isPublicOrganizationProfilePath(String path) => false;

String? legacyOrganizationRedirectForPath(String path, {String query = ''}) {
  if (path == '/organizations' || path.startsWith('/organizations/')) {
    return '/pc/home';
  }
  if (path.startsWith('/o/') || path == '/o') {
    return '/pc/home';
  }
  return null;
}

String? redirectLegacyOrganizationPath(GoRouterState state) {
  return legacyOrganizationRedirectForPath(
    state.uri.path,
    query: state.uri.query,
  );
}
