import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_invites.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/org_provider_list.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/shelter_tasks_provider.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_list_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/shelter_tasks/shelter_task_item.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/shelter_tasks/shelter_tasks_preview.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

class _OrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
    ),
    Organization(
      id: 'org-2',
      name: 'Paws Haven',
      type: OrganizationType.charity,
    ),
  ];
}

class _FakeShelterTasksNotifier extends ShelterTasksPreviewNotifier {
  _FakeShelterTasksNotifier(this.data);

  final ShelterTasksPreviewData data;

  @override
  Future<ShelterTasksPreviewData> build() async => data;
}

class _PendingInvitesNotifier extends PendingOrgInvitesNotifier {
  _PendingInvitesNotifier(this.invites);

  final List<PendingOrgInvite> invites;

  @override
  Future<List<PendingOrgInvite>> build() async => invites;
}

Widget _wrap(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ShelterTasksPreview', () {
    testWidgets('shows calm empty state when there are no tasks', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ShelterTasksPreview(), [
          shelterTasksPreviewProvider.overrideWith(
            () => _FakeShelterTasksNotifier(
              const ShelterTasksPreviewData(
                previewTasks: [],
                totalTaskCount: 0,
              ),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shelter_tasks_preview')), findsOneWidget);
      expect(find.byKey(const Key('shelter_tasks_empty')), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.text('Shelter tasks'), findsOneWidget);
    });

    testWidgets('folds pending invites into tasks block with actions', (
      tester,
    ) async {
      const invite = PendingOrgInvite(
        id: 'invite-1',
        organizationId: 'org-new',
        organizationName: 'New Rescue',
        organizationType: 'charity',
        desiredRole: 'admin',
        inviterName: 'Alex Admin',
        inviterEmail: 'alex@example.com',
        createdAt: '2026-01-01',
      );

      await tester.pumpWidget(
        _wrap(const ShelterTasksPreview(), [
          shelterTasksPreviewProvider.overrideWith(
            () => _FakeShelterTasksNotifier(
              const ShelterTasksPreviewData(
                previewTasks: [
                  ShelterTaskItem(
                    id: 'invite-invite-1',
                    kind: ShelterTaskKind.pendingInvite,
                    orgId: 'org-new',
                    orgName: 'New Rescue',
                    title: 'New Rescue',
                    routePath: '/o/orgs/org-new',
                    invite: invite,
                  ),
                ],
                totalTaskCount: 1,
              ),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("You've been invited to join New Rescue"),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shelter_task_accept_invite-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shelter_task_decline_invite-1')),
        findsOneWidget,
      );
      expect(find.text('Pending Invitations'), findsNothing);
    });

    testWidgets('shows pet attention tasks for multi-org preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ShelterTasksPreview(), [
          shelterTasksPreviewProvider.overrideWith(
            () => _FakeShelterTasksNotifier(
              const ShelterTasksPreviewData(
                previewTasks: [
                  ShelterTaskItem(
                    id: 'pet-org-1-max',
                    kind: ShelterTaskKind.petNeedAttention,
                    orgId: 'org-1',
                    orgName: 'Rescue Hearts',
                    title: 'Max',
                    routePath: '/o/orgs/org-1/pets',
                    attentionReason: OrgPetAttentionReason.notInFoster,
                  ),
                  ShelterTaskItem(
                    id: 'pet-org-2-bella',
                    kind: ShelterTaskKind.petNeedAttention,
                    orgId: 'org-2',
                    orgName: 'Paws Haven',
                    title: 'Bella',
                    routePath: '/o/orgs/org-2/pets',
                    attentionReason: OrgPetAttentionReason.fosterFinishingSoon,
                  ),
                ],
                totalTaskCount: 2,
              ),
            ),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Max'), findsOneWidget);
      expect(find.text('Bella'), findsOneWidget);
      expect(find.text('Rescue Hearts · Not in foster'), findsOneWidget);
      expect(find.text('Paws Haven · Foster finishing soon'), findsOneWidget);
    });
  });

  testWidgets(
    'organization list screen shows tasks section without separate invites header',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/o/orgs',
        routes: [
          GoRoute(
            path: '/o/orgs',
            builder: (context, state) => const OrganizationListScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            organizationListProvider.overrideWith(_OrgListNotifier.new),
            pendingOrgInvitesProvider.overrideWith(
              () => _PendingInvitesNotifier(const [
                PendingOrgInvite(
                  id: 'invite-1',
                  organizationId: 'org-new',
                  organizationName: 'New Rescue',
                  organizationType: 'charity',
                  desiredRole: 'admin',
                  inviterName: 'Alex Admin',
                  inviterEmail: 'alex@example.com',
                  createdAt: '2026-01-01',
                ),
              ]),
            ),
            shelterTasksPreviewProvider.overrideWith(
              () => _FakeShelterTasksNotifier(
                const ShelterTasksPreviewData(
                  previewTasks: [
                    ShelterTaskItem(
                      id: 'invite-invite-1',
                      kind: ShelterTaskKind.pendingInvite,
                      orgId: 'org-new',
                      orgName: 'New Rescue',
                      title: 'New Rescue',
                      routePath: '/o/orgs/org-new',
                      invite: PendingOrgInvite(
                        id: 'invite-1',
                        organizationId: 'org-new',
                        organizationName: 'New Rescue',
                        organizationType: 'charity',
                        desiredRole: 'admin',
                        inviterName: 'Alex Admin',
                        inviterEmail: 'alex@example.com',
                        createdAt: '2026-01-01',
                      ),
                    ),
                  ],
                  totalTaskCount: 1,
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shelter_tasks_preview')), findsOneWidget);
      expect(find.text('Pending Invitations'), findsNothing);
      expect(
        find.text("You've been invited to join New Rescue"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('org_membership_grid')), findsOneWidget);
    },
  );
}
