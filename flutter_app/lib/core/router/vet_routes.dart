import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../l10n/app_localizations.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/vet/presentation/screens/vet_detail_screen.dart';
import '../../features/vet/presentation/screens/vet_form_screen.dart';
import '../../features/vet/presentation/screens/vet_list_screen.dart';

List<RouteBase> buildVetExperienceRoutes() {
  return [
    GoRoute(
      path: '/pc/vets',
      name: 'petCareVets',
      builder: (context, state) => ExperienceShellScaffold(
        experience: AppExperience.petCare,
        currentLocation: state.uri.path,
        child: const VetListScreen(
          embeddedInShell: true,
          experience: AppExperience.petCare,
        ),
      ),
      routes: _vetFormRoutes(listPath: '/pc/vets'),
    ),
    GoRoute(
      path: '/g/vets',
      name: 'guardianVets',
      redirect: (context, state) => _legacyPetCareVetRedirect(state.uri.path),
    ),
    GoRoute(path: '/g/vets/add', redirect: (context, state) => '/pc/vets/add'),
    GoRoute(
      path: '/g/vets/edit/:id',
      redirect: (context, state) =>
          '/pc/vets/edit/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/g/vets/:id',
      redirect: (context, state) => '/pc/vets/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/o/vets',
      redirect: (context, state) => '/pc/vets',
    ),
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

List<RouteBase> _vetFormRoutes({required String listPath}) {
  return [
    GoRoute(
      path: 'add',
      name: 'petCareAddVet',
      builder: (context, state) {
        return VetFormScreen(listPath: listPath);
      },
    ),
    GoRoute(
      path: 'edit/:id',
      name: 'petCareEditVet',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        return VetFormScreen(vetId: vetId, listPath: listPath);
      },
    ),
    GoRoute(
      path: ':id',
      name: 'petCareVetDetail',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        final l = AppLocalizations.of(context)!;
        return ExperienceShellScaffold(
          experience: AppExperience.petCare,
          currentLocation: state.uri.path,
          screenTitle: l.careTeam,
          backPath: listPath,
          child: VetDetailScreen(vetId: vetId, listPath: listPath),
        );
      },
    ),
  ];
}

String? redirectLegacyVetPath(GoRouterState state) =>
    legacyVetRedirectForPath(state.uri.path);

String? legacyVetRedirectForPath(String path) {
  if (path == '/vets') return '/pc/vets';
  if (path == '/vets/add') return '/pc/vets/add';
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
