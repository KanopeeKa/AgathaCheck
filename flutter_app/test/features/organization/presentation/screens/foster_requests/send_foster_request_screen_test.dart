import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_request.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/foster_requests/foster_request_detail_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/foster_requests/send_foster_request_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('send foster request flow selects pets and fosters then sends', (
    tester,
  ) async {
    final repo = _SendFosterRequestRepo();

    final router = GoRouter(
      initialLocation: '/o/orgs/org-1/foster-requests/new',
      routes: [
        GoRoute(
          path: '/o/orgs/:id/foster-requests/new',
          builder: (context, state) {
            final orgId = state.pathParameters['id']!;
            return SendFosterRequestScreen(orgId: orgId);
          },
        ),
        GoRoute(
          path: '/o/orgs/:id/foster-requests/:requestId',
          builder: (context, state) {
            final orgId = state.pathParameters['id']!;
            final requestId = state.pathParameters['requestId']!;
            return FosterRequestDetailScreen(
              orgId: orgId,
              requestId: requestId,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(repo),
          organizationListProvider.overrideWith(() => _OrgListNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('send_foster_request_form')), findsOneWidget);
    expect(find.text('Send foster request'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('send_foster_request_message')),
      'Need help this weekend with Buddy',
    );
    await tester.tap(find.byKey(const Key('send_foster_request_pet_pet-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send_foster_request_foster_fp-1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send_foster_request_send')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.lastSend, true);
    expect(repo.lastMessage, 'Need help this weekend with Buddy');
    expect(repo.lastPetIds, ['pet-1']);
    expect(repo.lastFosterIds, ['fp-1']);
    expect(find.text('Foster request sent'), findsOneWidget);
    expect(find.byKey(const Key('foster_request_detail_body')), findsOneWidget);
  });
}

class _OrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [
    const Organization(
      id: 'org-1',
      name: 'Test Shelter',
      type: OrganizationType.charity,
      role: 'admin',
    ),
  ];
}

class _SendFosterRequestRepo extends RecordingOrganizationRepository {
  int createCalls = 0;
  bool lastSend = false;
  String lastMessage = '';
  List<String> lastPetIds = [];
  List<String> lastFosterIds = [];

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) async => [
    {'id': 'pet-1', 'name': 'Buddy', 'species': 'dog', 'passed_away': false},
  ];

  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async => const [
    FosterParent(
      id: 'fp-1',
      kind: FosterParentKind.member,
      userId: 'user-1',
      displayName: 'Jane Foster',
      email: 'jane@example.com',
      approvalState: FosterApprovalState.approved,
    ),
  ];

  @override
  Future<FosterRequest> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
    required String token,
  }) async {
    createCalls++;
    lastSend = send;
    lastMessage = message;
    lastPetIds = petIds;
    lastFosterIds = orgFosterParentIds;
    return FosterRequest(
      id: 'fr-created',
      organizationId: orgId,
      message: message,
      status: send ? FosterRequestStatus.sent : FosterRequestStatus.draft,
      pets: [
        const FosterRequestPet(
          petId: 'pet-1',
          petName: 'Buddy',
          species: 'dog',
        ),
      ],
      targets: [
        const FosterRequestTarget(
          orgFosterParentId: 'fp-1',
          displayName: 'Jane Foster',
        ),
      ],
      targetCount: orgFosterParentIds.length,
    );
  }

  @override
  Future<FosterRequest> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  ) async => FosterRequest(
    id: requestId,
    organizationId: orgId,
    message: lastMessage,
    status: FosterRequestStatus.sent,
    pets: const [
      FosterRequestPet(petId: 'pet-1', petName: 'Buddy', species: 'dog'),
    ],
    targets: const [
      FosterRequestTarget(
        orgFosterParentId: 'fp-1',
        displayName: 'Jane Foster',
      ),
    ],
    targetCount: 1,
  );
}
