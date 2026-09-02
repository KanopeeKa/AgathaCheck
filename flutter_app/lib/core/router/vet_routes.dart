import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../l10n/app_localizations.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/organization/presentation/utils/org_profile_return.dart';
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
      name: 'orgVets',
      builder: (context, state) => ExperienceShellScaffold(
        experience: AppExperience.organization,
        currentLocation: state.uri.path,
        child: const VetListScreen(
          embeddedInShell: true,
          experience: AppExperience.organization,
        ),
      ),
      routes: _vetFormRoutes(listPath: '/o/vets'),
    ),
  ];
}

List<RouteBase> _vetFormRoutes({required String listPath}) {
  final isPetCare = listPath == '/pc/vets';
  return [
    GoRoute(
      path: 'add',
      name: '${isPetCare ? 'petCare' : 'org'}AddVet',
      builder: (context, state) {
        final orgId = state.uri.queryParameters['org'];
        return VetFormScreen(listPath: listPath, defaultOrganizationId: orgId);
      },
    ),
    GoRoute(
      path: 'edit/:id',
      name: '${isPetCare ? 'petCare' : 'org'}EditVet',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        return VetFormScreen(vetId: vetId, listPath: listPath);
      },
    ),
    GoRoute(
      path: ':id',
      name: '${isPetCare ? 'petCare' : 'org'}VetDetail',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        final l = AppLocalizations.of(context)!;
        final returnTo = orgProfileReturnToFromState(state);
        return ExperienceShellScaffold(
          experience: isPetCare
              ? AppExperience.petCare
              : AppExperience.organization,
          currentLocation: state.uri.path,
          screenTitle: l.careTeam,
          backPath: returnTo,
          forceBackPath: returnTo != null,
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
