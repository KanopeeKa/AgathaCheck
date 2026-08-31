import 'package:flutter/material.dart';
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
      path: '/g/vets',
      name: 'guardianVets',
      builder: (context, state) => ExperienceShellScaffold(
        experience: AppExperience.guardian,
        currentLocation: state.uri.path,
        child: const VetListScreen(
          embeddedInShell: true,
          experience: AppExperience.guardian,
        ),
      ),
      routes: _vetFormRoutes(listPath: '/g/vets'),
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
  return [
    GoRoute(
      path: 'add',
      name: '${listPath == '/g/vets' ? 'guardian' : 'org'}AddVet',
      builder: (context, state) {
        final orgId = state.uri.queryParameters['org'];
        return VetFormScreen(listPath: listPath, defaultOrganizationId: orgId);
      },
    ),
    GoRoute(
      path: 'edit/:id',
      name: '${listPath == '/g/vets' ? 'guardian' : 'org'}EditVet',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        return VetFormScreen(vetId: vetId, listPath: listPath);
      },
    ),
    GoRoute(
      path: ':id',
      name: '${listPath == '/g/vets' ? 'guardian' : 'org'}VetDetail',
      builder: (context, state) {
        final vetId = state.pathParameters['id']!;
        final l = AppLocalizations.of(context)!;
        return ExperienceShellScaffold(
          experience: listPath == '/g/vets'
              ? AppExperience.guardian
              : AppExperience.organization,
          currentLocation: state.uri.path,
          screenTitle: l.careTeam,
          child: VetDetailScreen(vetId: vetId, listPath: listPath),
        );
      },
    ),
  ];
}

String? redirectLegacyVetPath(GoRouterState state) =>
    legacyVetRedirectForPath(state.uri.path);

String? legacyVetRedirectForPath(String path) {
  if (path == '/vets') return '/g/vets';
  if (path == '/vets/add') return '/g/vets/add';
  final editMatch = RegExp(r'^/vets/edit/([^/]+)$').firstMatch(path);
  if (editMatch != null) {
    return '/g/vets/edit/${editMatch.group(1)}';
  }
  return null;
}
