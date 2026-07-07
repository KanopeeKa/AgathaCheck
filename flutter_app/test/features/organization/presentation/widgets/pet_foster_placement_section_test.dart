import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization_member.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/pet_foster_placement_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

void main() {
  testWidgets('placement section shows not-in-foster actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _NotInFosterPlacementRepo(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetFosterPlacementSection(
              orgId: 'org-1',
              petId: 'pet-1',
              petName: 'Max',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Foster placement'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('start_foster_placement_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('direct_adopt_button')), findsOneWidget);
  });

  testWidgets(
    'start placement shows snackbar when no member foster parents exist',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => FakeAuthNotifier()),
            organizationRepositoryProvider.overrideWithValue(
              _EmptyFosterParentsRepo(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PetFosterPlacementSection(
                orgId: 'org-1',
                petId: 'pet-1',
                petName: 'Max',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Foster placement'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_foster_placement_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Add a foster parent with an app account first (invite by email).',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('start placement opens foster parent picker for member fosters', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            _MemberFosterParentsRepo(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetFosterPlacementSection(
              orgId: 'org-1',
              petId: 'pet-1',
              petName: 'Max',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Foster placement'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_foster_placement_button')));
    await tester.pumpAndSettle();

    expect(find.text('Start foster placement'), findsWidgets);
    expect(find.text('Jane Foster'), findsOneWidget);
    expect(find.text('Foster parents'), findsOneWidget);
  });
}

class _NotInFosterPlacementRepo extends RecordingOrganizationRepository {
  @override
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async => const PetFosterPlacementState(status: 'not_in_foster');
}

class _EmptyFosterParentsRepo extends _NotInFosterPlacementRepo {
  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async => const [
    FosterParent(
      id: 'fp-1',
      kind: FosterParentKind.external,
      displayName: 'Off-app Parent',
      email: 'off@example.com',
    ),
  ];
}

class _MemberFosterParentsRepo extends _NotInFosterPlacementRepo {
  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async => const [
    FosterParent(
      id: 'ou-1',
      kind: FosterParentKind.member,
      userId: 'user-1',
      displayName: 'Jane Foster',
      email: 'jane@example.com',
      role: OrgMemberRole.foster,
    ),
  ];
}
