import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/organization/presentation/widgets/org_shell_app_bar_title.dart';
import '../../l10n/app_localizations.dart';
import '../../features/organization/presentation/screens/organization_people_screen.dart';
import '../../features/organization/presentation/screens/accept_connection_screen.dart';
import '../../features/organization/presentation/screens/archived_pet_detail_screen.dart';
import '../../features/organization/presentation/screens/archived_pets_screen.dart';
import '../../features/organization/presentation/screens/organization_connections_screen.dart';
import '../../features/organization/presentation/screens/organization_discover_screen.dart';
import '../../features/organization/presentation/utils/org_discover_entry_context.dart';
import '../../features/organization/presentation/screens/organization_customisations_screen.dart';
import '../../features/organization/presentation/screens/organisation_profile_screen.dart';
import '../../features/organization/presentation/screens/organisation_redacted_pet_screen.dart';
import '../../features/organization/presentation/screens/organization_document_templates_screen.dart';
import '../../features/organization/presentation/screens/organization_form_screen.dart';
import '../../features/organization/presentation/screens/organization_legal_documents_screen.dart';
import '../../features/organization/presentation/screens/organization_list_screen.dart';
import '../../features/organization/presentation/screens/organization_roles_permissions_screen.dart';
import '../../features/organization/presentation/utils/org_people_route_params.dart';
import '../../features/organization/presentation/screens/adoption_journey/adoption_journey_detail_screen.dart';
import '../../features/organization/presentation/screens/adoption_screening/adoption_visits_screen.dart';
import '../../features/organization/presentation/screens/adoption_screening/prospects_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_request_detail_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_request_respond_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/foster_requests_screen.dart';
import '../../features/organization/presentation/screens/foster_requests/send_foster_request_screen.dart';
import '../../features/organization/presentation/screens/fostering_session/fostering_session_detail_screen.dart';
import '../../features/organization/presentation/screens/fostering_sessions/fostering_sessions_list_screen.dart';
import '../../features/organization/presentation/screens/manage_fosters/manage_fosters_screen.dart';
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
      builder: (context, state) {
        final l = AppLocalizations.of(context)!;
        return ExperienceShellScaffold(
          experience: AppExperience.organization,
          currentLocation: state.uri.path,
          screenTitle: l.organisationsDashboardTitle,
          orgNavVariant: OrgNavTitleVariant.dashboard,
          contextualActions: [
            IconButton(
              key: const Key('org_nav_create'),
              icon: const Icon(Icons.add),
              tooltip: l.createOrganization,
              onPressed: () => context.push('/o/orgs/new'),
            ),
          ],
          child: const OrganizationListScreen(embeddedInShell: true),
        );
      },
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
      path: 'discover',
      name: 'organizationDiscover',
      builder: (context, state) {
        final from = parseOrgDiscoverEntryContext(
          state.uri.queryParameters['from'],
        );
        final orgId = state.uri.queryParameters['orgId'];
        return OrganizationDiscoverScreen(from: from, orgId: orgId);
      },
    ),
    GoRoute(
      path: ':id',
      name: 'organizationDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OrganisationProfileScreen(orgId: id);
      },
      routes: [
        GoRoute(
          path: 'presentation',
          name: 'organizationPresentation',
          redirect: (context, state) {
            final id = state.pathParameters['id']!;
            return '/o/orgs/$id';
          },
        ),
        GoRoute(
          path: 'legal-documents',
          name: 'organizationLegalDocuments',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationLegalDocumentsScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'connections',
          name: 'organizationConnections',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationConnectionsScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'edit',
          name: 'editOrganization',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationFormScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'customisations',
          name: 'organizationCustomisations',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return OrganizationCustomisationsScreen(orgId: id);
          },
          routes: [
            GoRoute(
              path: 'templates',
              name: 'organizationDocumentTemplates',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return OrganizationDocumentTemplatesScreen(orgId: id);
              },
            ),
            GoRoute(
              path: 'roles',
              name: 'organizationRolesPermissions',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final initialPeopleIds = parseOrgPeopleIdsQuery(
                  state.uri.queryParameters['people'],
                );
                return OrganizationRolesPermissionsScreen(
                  orgId: id,
                  initialPeopleIds: initialPeopleIds,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'people',
          name: 'organizationPeople',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final filter = state.uri.queryParameters['filter'];
            return OrganizationPeopleScreen(orgId: id, filter: filter);
          },
        ),
        GoRoute(
          path: 'admin-contacts',
          name: 'organizationAdminContacts',
          redirect: (context, state) {
            final id = state.pathParameters['id']!;
            return '/o/orgs/$id/people?filter=admins';
          },
        ),
        GoRoute(
          path: 'members',
          name: 'organizationMembers',
          redirect: (context, state) => '/o/orgs/${state.pathParameters['id']}',
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
          path: 'prospects',
          name: 'prospects',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProspectsScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'adoption-visits',
          name: 'adoptionVisits',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return AdoptionVisitsScreen(orgId: id);
          },
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
          routes: [
            GoRoute(
              path: ':petId/redacted',
              name: 'organizationRedactedPet',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final petId = state.pathParameters['petId']!;
                return OrganisationRedactedPetScreen(orgId: id, petId: petId);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'sessions',
          name: 'fosteringSessionsList',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return FosteringSessionsListScreen(orgId: id);
          },
        ),
        GoRoute(
          path: 'placements/:placementId/session',
          name: 'fosteringSessionDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final placementId = state.pathParameters['placementId']!;
            return FosteringSessionDetailScreen(
              orgId: id,
              placementId: placementId,
            );
          },
        ),
        GoRoute(
          path: 'placements/:placementId/adoption-journey',
          name: 'adoptionJourneyDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final placementId = state.pathParameters['placementId']!;
            return AdoptionJourneyDetailScreen(
              orgId: id,
              placementId: placementId,
            );
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

const _reservedOrgRouteSegments = {'new', 'join', 'connect'};

/// Anonymous visitors may view discoverable organisation public profiles.
bool isPublicOrganizationProfilePath(String path) {
  final segments = Uri.parse(path).pathSegments;
  if (segments.length != 3) return false;
  if (segments[0] != 'o' || segments[1] != 'orgs') return false;
  return !_reservedOrgRouteSegments.contains(segments[2]);
}
