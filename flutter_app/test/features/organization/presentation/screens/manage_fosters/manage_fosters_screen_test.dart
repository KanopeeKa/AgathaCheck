import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/manage_fosters/manage_fosters_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('Manage Fosters screen shows tabs and foster cards', (
    tester,
  ) async {
    const parents = [
      FosterParent(
        id: 'fp-1',
        kind: FosterParentKind.member,
        userId: 'user-1',
        displayName: 'Eve Foster',
        email: 'eve@example.com',
        activePetCount: 1,
        activePets: [
          FosterParentAssignedPet(
            petId: 'pet-1',
            petName: 'Max',
            status: 'in_progress',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _FosterParentsRepo(parents),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ManageFostersScreen(orgId: 'org-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manage_fosters_tabs')), findsOneWidget);
    expect(find.text('Manage fosters'), findsOneWidget);
    expect(find.byKey(const Key('foster_summary_card_fp-1')), findsOneWidget);
    expect(find.text('Eve Foster'), findsOneWidget);
  });

  testWidgets('external foster menu offers merge into registered account', (
    tester,
  ) async {
    const parents = [
      FosterParent(
        id: 'fp-ext-1',
        kind: FosterParentKind.external,
        displayName: 'Manual Parent',
        email: 'match@example.com',
        approvalState: FosterApprovalState.underReview,
      ),
    ];
    final repo = _MergeFosterRepo(parents);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ManageFostersScreen(orgId: 'org-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('foster_actions_menu_fp-ext-1')));
    await tester.pumpAndSettle();
    expect(find.text('Link to registered account'), findsOneWidget);

    await tester.tap(find.text('Link to registered account'));
    await tester.pumpAndSettle();

    expect(find.text('Link foster record?'), findsOneWidget);
    await tester.tap(find.text('Link account'));
    await tester.pumpAndSettle();

    expect(repo.mergeCalls, 1);
    expect(
      find.text('Foster record linked to registered account'),
      findsOneWidget,
    );
  });
}

class _MergeFosterRepo extends _FosterParentsRepo {
  _MergeFosterRepo(super.parents);

  int mergeCalls = 0;

  @override
  Future<List<FosterMergeSuggestion>> getFosterMergeSuggestions(
    String orgId,
    String email, {
    required String token,
  }) async => [
    const FosterMergeSuggestion(
      userId: 'registered-user-1',
      displayName: 'Registered User',
      email: 'match@example.com',
    ),
  ];

  @override
  Future<FosterParent> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  }) async {
    mergeCalls++;
    return FosterParent(
      id: fosterParentId,
      kind: FosterParentKind.external,
      userId: targetUserId,
      displayName: 'Manual Parent',
      email: 'match@example.com',
    );
  }
}

class _FosterParentsRepo extends RecordingOrganizationRepository {
  _FosterParentsRepo(this._parents);

  final List<FosterParent> _parents;

  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async => _parents;
}
