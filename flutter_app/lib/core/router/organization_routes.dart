import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/organization/presentation/screens/accept_connection_screen.dart';
import '../../features/organization/presentation/screens/archived_pet_detail_screen.dart';
import '../../features/organization/presentation/screens/archived_pets_screen.dart';
import '../../features/organization/presentation/screens/organization_detail_screen.dart';
import '../../features/organization/presentation/screens/organization_form_screen.dart';
import '../../features/organization/presentation/screens/organization_list_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_request_detail_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_request_respond_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_requests_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/send_foster_request_screen.dart';
import '../../features/organization/presentation/screens/manage_fosters/manage_fosters_screen.dart';
import '../../features/organization/presentation/screens/organization_members_screen.dart';
import '../../features/organization/presentation/screens/organization_person_detail_screen.dart';
import '../../features/organization/presentation/screens/organization_pets_screen.dart';
import '../../features/organization/presentation/screens/transfer_pet_screen.dart';
import '../../features/organization/presentation/screens/transfer_pet_to_org_screen.dart';

/// Org management routes under `/o/orgs` (org-mode shell on the list hub).
List<RouteBase> buildOrgManagementRoutes() {
  return [
    GoRoute(
      path: '/o/orgs',
      name: 'orgOrganizations',
      builder: (context, state) => ExperienceShellScaffold(
        experience: AppExperience.organization,
        currentLocation: state.uri.path,
        child: const OrganizationListScreen(embeddedInShell: true),
      ),
      routes: _orgManagementChildRoutes(),
    ),
  ];
}

List<RouteBase> _orgManagementChildRoutes() {
  return [
    GoRoute(
      path: 'new',
      name: 'createOrganization',
      builder: (context, state) => const OrganizationFormScreen(),
    ),
    GoRoute(
      path: 'join/:code',
      name: 'joinOrganization',
      redirect: (context, state) => '/o/orgs',
    ),
    GoRoute(
      path: 'connect/:token',
      name: 'acceptOrgConnection',
      builder: (context, state) {
        final token = state.pathParameters['token']!;
        return AcceptConnectionScreen(token: token);
      },
    ),
    GoRoute(
      path: ':id',
      name: 'organizationDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrganizationDetailScreen(orgId: id);
      },
      routes: [
        GoRoute(
          path: 'edit',
          name: 'editOrganization',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationFormScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'members',
          name: 'organizationMembers',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationMembersScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'fosters',
          name: 'manageFosters',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ManageFostersScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'foster-requests',
          name: 'fosterRequests',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return FosterRequestsScreen(orgId: id);
          },
          routes: [
            GoRoute(
              path: 'new',
              name: 'sendFosterRequest',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return SendFosterRequestScreen(orgId: id);
              },
            ),
            GoRoute(
              path: ':requestId',
              name: 'fosterRequestDetail',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final requestId = state.pathParameters['requestId']!;
                return FosterRequestDetailScreen(
                  orgId: id,
                  requestId: requestId,
                );
              },
              routes: [
                GoRoute(
                  path: 'respond',
                  name: 'fosterRequestRespond',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final requestId = state.pathParameters['requestId']!;
                    return FosterRequestRespondScreen(
                      orgId: id,
                      requestId: requestId,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: 'people/:kind/:personId',
          name: 'organizationPersonDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final kind = state.pathParameters['kind']!;
            final personId = state.pathParameters['personId']!;
            return OrganizationPersonDetailScreen(
              orgId: id,
              kind: kind,
              recordId: personId,
            );
          },
        ),
        GoRoute(
          path: 'pets',
          name: 'organizationPets',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationPetsScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'transfer/:petId',
          name: 'transferPet',
          builder: (context, state) {
            final orgId = state.pathParameters['id']!;
            final petId = state.pathParameters['petId']!;
            return TransferPetScreen(orgId: orgId, petId: petId);
          },
          routes: [
            GoRoute(
              path: 'to-org',
              name: 'transferPetToOrg',
              builder: (context, state) {
                final orgId = state.pathParameters['id']!;
                final petId = state.pathParameters['petId']!;
                return TransferPetToOrgScreen(orgId: orgId, petId: petId);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'archived',
          name: 'organizationArchived',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ArchivedPetsScreen(orgId: id);
          },
          routes: [
            GoRoute(
              path: ':archiveId',
              name: 'archivedPetDetail',
              builder: (context, state) {
                final orgId = state.pathParameters['id']!;
                final archiveId = state.pathParameters['archiveId']!;
                return ArchivedPetDetailScreen(
                  orgId: orgId,
                  archiveId: archiveId,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ];
}

/// One-release-cycle compat: `/organizations/*` → `/o/orgs/*`.
String? legacyOrganizationRedirectForPath(String path, {String query = ''}) {
  if (path == '/organizations') {
    return _withQuery('/o/orgs', query);
  }
  if (path.startsWith('/organizations/')) {
    final suffix = path.substring('/organizations'.length);
    return _withQuery('/o/orgs$suffix', query);
  }
  return null;
}

String? redirectLegacyOrganizationPath(GoRouterState state) {
  return legacyOrganizationRedirectForPath(
    state.uri.path,
    query: state.uri.query,
  );
}

String _withQuery(String path, String query) {
  if (query.isEmpty) return path;
  return '$path?$query';
}
