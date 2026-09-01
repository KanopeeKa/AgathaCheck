import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/fostering_session/data/fostering_session_repository.dart';
import 'package:pet_profile_app/features/fostering_session/domain/entities/session_viewer_context.dart';
import 'package:pet_profile_app/features/fostering_session/presentation/providers/fostering_session_repository_provider.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_session_status.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/fostering_session/fostering_session_detail_screen.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/pet_foster_placement_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets(
    'session detail shows preparation checklist and transition action',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            shelterFosteringSessionRepositoryProvider.overrideWith(
              (ref) => FosteringSessionRepository(
                loadShelterRow: (_, __, ___) async => _preparationDetailJson(),
              ),
            ),
            organizationRepositoryProvider.overrideWithValue(
              _PreparationSessionRepo(),
            ),
            isOrgAdminProvider('org-1').overrideWith((ref) => true),
            isOrgFosterProvider('org-1').overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FosteringSessionDetailScreen(
                orgId: 'org-1',
                placementId: 'placement-1',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fostering_session_detail_body')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fostering_session_preparation_checklist')),
        findsOneWidget,
      );
      expect(find.text('Preparation checklist'), findsOneWidget);
      expect(
        find.byKey(const Key('session_checklist_item_foster_contract_signed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fostering_session_mark_ready')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('fostering_session_register_export')),
        findsOneWidget,
      );
    },
  );

  testWidgets('session checklist toggles call repository', (tester) async {
    final repo = _ChecklistToggleRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          shelterFosteringSessionRepositoryProvider.overrideWith(
            (ref) => FosteringSessionRepository(
              loadShelterRow: (_, __, ___) async => _preparationDetailJson(),
            ),
          ),
          organizationRepositoryProvider.overrideWithValue(repo),
          isOrgAdminProvider('org-1').overrideWith((ref) => true),
          isOrgFosterProvider('org-1').overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosteringSessionDetailScreen(
              orgId: 'org-1',
              placementId: 'placement-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('session_checklist_item_foster_contract_signed')),
    );
    await tester.pumpAndSettle();

    expect(repo.updateSessionChecklistCalls, 1);
    expect(repo.lastChecklistItemKey, 'foster_contract_signed');
    expect(repo.lastChecklistCompleted, true);
  });

  testWidgets('placement section links to fostering session when open', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: PetFosterPlacementSection(
              orgId: 'org-1',
              petId: 'pet-1',
              petName: 'Max',
            ),
          ),
        ),
        GoRoute(
          path: '/o/orgs/:orgId/placements/:placementId/session',
          redirect: (context, state) {
            final orgId = state.pathParameters['orgId']!;
            final placementId = state.pathParameters['placementId']!;
            return '/o/orgs/$orgId/sessions/$placementId';
          },
        ),
        GoRoute(
          path: '/o/orgs/:orgId/sessions/:placementId',
          builder: (context, state) =>
              const Scaffold(body: Text('Session detail route')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _OpenSessionPlacementRepo(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Foster placement'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('view_fostering_session_button')));
    await tester.pumpAndSettle();

    expect(find.text('Session detail route'), findsOneWidget);
  });
  testWidgets('view-to-adopt session shows expedite adoption action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          shelterFosteringSessionRepositoryProvider.overrideWith(
            (ref) => FosteringSessionRepository(
              loadShelterRow: (_, __, ___) async => _viewToAdoptDetailJson(),
            ),
          ),
          organizationRepositoryProvider.overrideWithValue(
            _PreparationSessionRepo(),
          ),
          isOrgAdminProvider('org-1').overrideWith((ref) => true),
          isOrgFosterProvider('org-1').overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosteringSessionDetailScreen(
              orgId: 'org-1',
              placementId: 'placement-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('fostering_session_expedite_adoption')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('fostering_session_start_adoption')),
      findsOneWidget,
    );
  });
}

Map<String, dynamic> _preparationDetailJson() => {
  'id': 'placement-1',
  'organization_id': 'org-1',
  'pet_id': 'pet-1',
  'foster_user_id': 'user-1',
  'status': 'pending',
  'session_status': FosterSessionStatus.preparation,
  'pet_name': 'Max',
  'foster_name': 'Jane Foster',
  'viewer': {
    'role': SessionViewerRole.shelterOperator,
    'allowed_actions': [
      SessionAction.transitionReadyToStart,
      SessionAction.updateChecklistItem,
      SessionAction.registerExport,
    ],
  },
  'checklist': {
    'items': [
      {
        'key': 'foster_contract_signed',
        'label': 'Foster contract signed',
        'completed': false,
        'is_required': true,
      },
    ],
  },
};

Map<String, dynamic> _viewToAdoptDetailJson() => {
  'id': 'placement-1',
  'organization_id': 'org-1',
  'pet_id': 'pet-1',
  'foster_user_id': 'user-1',
  'status': 'in_progress',
  'session_status': FosterSessionStatus.active,
  'session_type': FosterSessionType.fosterInViewToAdopt,
  'pet_name': 'Max',
  'foster_name': 'Jane Foster',
  'viewer': {
    'role': SessionViewerRole.shelterOperator,
    'allowed_actions': [
      SessionAction.startAdoptionJourney,
      SessionAction.expediteVisitAdoption,
      SessionAction.registerExport,
    ],
  },
};

class _PreparationSessionRepo extends RecordingOrganizationRepository {
  @override
  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  ) async => {
    'items': [
      {
        'key': 'foster_contract_signed',
        'label': 'Foster contract signed',
        'completed': false,
        'is_required': true,
      },
    ],
  };
}

class _ChecklistToggleRepo extends _PreparationSessionRepo {
  var updateSessionChecklistCalls = 0;
  String? lastChecklistItemKey;
  bool? lastChecklistCompleted;

  @override
  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  }) async {
    updateSessionChecklistCalls++;
    lastChecklistItemKey = itemKey;
    lastChecklistCompleted = completed;
    return {
      'items': [
        {
          'key': itemKey,
          'label': 'Foster contract signed',
          'completed': completed,
          'is_required': true,
        },
      ],
    };
  }
}

class _OpenSessionPlacementRepo extends RecordingOrganizationRepository {
  @override
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async {
    final placement = FosterPlacement(
      id: 'placement-1',
      organizationId: orgId,
      petId: petId,
      fosterUserId: 'user-1',
      status: 'pending',
      sessionStatus: FosterSessionStatus.preparation,
      petName: 'Max',
      fosterName: 'Jane Foster',
    );
    return PetFosterPlacementState(
      status: placement.status,
      placement: placement,
    );
  }
}
