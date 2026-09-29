import 'package:go_router/go_router.dart';

import '../../features/people/presentation/screens/people_legacy_vet_redirect_screen.dart';

List<RouteBase> buildVetExperienceRoutes() {
  return [
    GoRoute(
      path: '/pc/vets',
      name: 'petCareVets',
      redirect: (context, state) {
        final path = state.uri.path;
        if (path == '/pc/vets' || path == '/pc/vets/') {
          return '/pc/people?filter=professionals';
        }
        if (path == '/pc/vets/add') {
          return '/pc/people/new';
        }
        return null;
      },
      routes: _vetLegacyRoutes(),
    ),
    GoRoute(
      path: '/g/vets',
      name: 'guardianVets',
      redirect: (context, state) => _legacyPetCareVetRedirect(state.uri.path),
    ),
    GoRoute(
      path: '/g/vets/add',
      redirect: (context, state) => '/pc/people/new',
    ),
    GoRoute(
      path: '/g/vets/edit/:id',
      redirect: (context, state) =>
          '/pc/vets/edit/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/g/vets/:id',
      redirect: (context, state) => '/pc/vets/${state.pathParameters['id']}',
    ),
    GoRoute(path: '/o/vets', redirect: (context, state) => '/pc/vets'),
    GoRoute(
      path: '/o/vets/:tail(.*)',
      redirect: (context, state) {
        final tail = state.pathParameters['tail'] ?? '';
        if (tail.isEmpty) return '/pc/vets';
        return '/pc/vets/$tail';
      },
    ),
  ];
}

List<RouteBase> _vetLegacyRoutes() {
  return [
    GoRoute(
      path: 'add',
      name: 'petCareAddVet',
      redirect: (context, state) => '/pc/people/new',
    ),
    GoRoute(
      path: 'edit/:id',
      name: 'petCareEditVet',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        return PeopleLegacyVetRedirectScreen(vetId: vetId, edit: true);
      },
    ),
    GoRoute(
      path: ':id',
      name: 'petCareVetDetail',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        return PeopleLegacyVetRedirectScreen(vetId: vetId);
      },
    ),
  ];
}

String? redirectLegacyVetPath(GoRouterState state) =>
    legacyVetRedirectForPath(state.uri.path);

String? legacyVetRedirectForPath(String path) {
  if (path == '/vets') return '/pc/vets';
  if (path == '/vets/add') return '/pc/people/new';
  final editMatch = RegExp(r'^/vets/edit/([^/]+)$').firstMatch(path);
  if (editMatch != null) {
    return '/pc/vets/edit/${editMatch.group(1)}';
  }
  return null;
}

String _legacyPetCareVetRedirect(String path) {
  if (path == '/g/vets') return '/pc/vets';
  if (path.startsWith('/g/vets/')) {
    return '/pc${path.substring(2)}';
  }
  return '/pc/vets';
}
