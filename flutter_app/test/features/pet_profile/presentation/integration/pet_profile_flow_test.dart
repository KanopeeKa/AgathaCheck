@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/experience/data/guardian_onboarding_store.dart';
import 'package:pet_profile_app/features/experience/data/org_onboarding_store.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_helpers.dart';

final guardianOnlyEligibility = ExperienceEligibilityRules.compute(
  pets: const [],
  orgMembershipCount: 0,
);

final experienceOverrides = [
  experienceEligibilityProvider.overrideWith(
    (ref) => AsyncValue.data(guardianOnlyEligibility),
  ),
];

final fakePetRepositoryOverride = petRepositoryProvider.overrideWithValue(
  FakePetRepository(),
);
final petsOverride = getAllPetsUseCaseProvider.overrideWith(
  (ref) => FakeGetAllPets(),
);
final authOverride = authProvider.overrideWith((ref) => FakeAuthNotifier());

class _EmptyPendingOrgInvitesNotifier extends PendingOrgInvitesNotifier {
  @override
  Future<List<PendingOrgInvite>> build() async => const [];
}

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        GuardianOnboardingStore.completedKey: true,
        OrgOnboardingStore.completedKey: true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    List<Override> baseOverrides(SharedPreferences prefs) => [
      sharedPreferencesProvider.overrideWithValue(prefs),
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      authOverride,
      petsOverride,
      fakePetRepositoryOverride,
      vetListProvider.overrideWith(FakeVetListNotifier.new),
      organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
      pendingOrgInvitesProvider.overrideWith(
        _EmptyPendingOrgInvitesNotifier.new,
      ),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
      healthEntriesNotifierProvider.overrideWith(
        () => FakeHealthEntriesNotifier(),
      ),
      notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
      notificationPreferencesProvider.overrideWith(
        () => FakeNotificationPreferencesNotifier(),
      ),
      pendingSharesProvider.overrideWith(() => FakePendingSharesNotifier()),
      ...experienceOverrides,
    ];

    Future<void> pumpGuardianHome(WidgetTester tester) async {
      await pumpApp(tester, frames: 5);
      await tester.pumpAndSettle();
      var trackPetsTapped = false;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final ftueTrackPets = find.byKey(const Key('ftue_action_track_pets'));
        final isTrackPetsRouteActive =
            ftueTrackPets.evaluate().isNotEmpty &&
            ModalRoute.of(tester.element(ftueTrackPets))?.isCurrent == true;
        if (!trackPetsTapped && isTrackPetsRouteActive) {
          await tester.ensureVisible(ftueTrackPets);
          await tester.tapAt(tester.getCenter(ftueTrackPets));
          await pumpApp(tester, frames: 5);
          trackPetsTapped = true;
        }
        if (find
                .byKey(const Key('guardian_dashboard_pet_preview'))
                .evaluate()
                .isNotEmpty &&
            find
                .byKey(const Key('guardian_dashboard_add_pet'))
                .evaluate()
                .isNotEmpty) {
          return;
        }
      }
    }

    Future<void> navigateToAddPetForm(WidgetTester tester) async {
      final addPet = find.byKey(const Key('guardian_dashboard_add_pet'));
      await tester.ensureVisible(addPet);
      await tester.tapAt(tester.getCenter(addPet));
      await pumpApp(tester, frames: 5);
    }

    testWidgets('shows empty state initially', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(
        () => testNotifier,
      );
      await tester.pumpWidget(
        createApp(
          prefs: prefs,
          overrides: [...baseOverrides(prefs), emptyPetListOverride],
        ),
      );
      await pumpGuardianHome(tester);

      expect(
        find.byKey(const Key('guardian_dashboard_pet_preview')),
        findsOneWidget,
        reason: 'Should show the empty pet preview rail',
      );
      expect(
        find.byKey(const Key('guardian_dashboard_add_pet')),
        findsOneWidget,
        reason: 'Should offer an add-pet action on the empty dashboard',
      );
    });

    testWidgets('navigates to add pet form', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(
        () => testNotifier,
      );
      await tester.pumpWidget(
        createApp(
          prefs: prefs,
          overrides: [...baseOverrides(prefs), emptyPetListOverride],
        ),
      );
      await pumpGuardianHome(tester);

      final l10n = l10nFromTester(tester);

      await navigateToAddPetForm(tester);

      expect(
        find.text(l10n.petName),
        findsOneWidget,
        reason: 'Should show pet name field',
      );
      expect(
        find.text(l10n.species),
        findsOneWidget,
        reason: 'Should show species field',
      );
      expect(
        find.text(l10n.savePet),
        findsOneWidget,
        reason: 'Should show save pet button',
      );
    });

    testWidgets('validates required name field', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(
        () => testNotifier,
      );
      await tester.pumpWidget(
        createApp(
          prefs: prefs,
          overrides: [...baseOverrides(prefs), emptyPetListOverride],
        ),
      );
      await pumpGuardianHome(tester);

      final l10n = l10nFromTester(tester);

      await navigateToAddPetForm(tester);

      final saveButton = find.byKey(const Key('save_pet_button'));
      await tester.ensureVisible(saveButton);
      await pumpApp(tester);
      await tester.tap(saveButton, warnIfMissed: false);
      await pumpApp(tester);

      expect(
        find.text(l10n.petNameRequired),
        findsOneWidget,
        reason: 'Should show required name validation',
      );
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      final testNotifier = TestPetListNotifier();
      final petListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(
        createApp(
          prefs: prefs,
          overrides: [...baseOverrides(prefs), petListOverride],
        ),
      );
      await pumpGuardianHome(tester);

      await navigateToAddPetForm(tester);

      await tester.enterText(find.byKey(const Key('pet_name_field')), 'Buddy');
      await tester.tap(find.byKey(const Key('pet_species_field')));
      await pumpApp(tester);
      await tester.tap(find.text('Dog').last);
      await pumpApp(tester);

      final saveButton = find.byKey(const Key('save_pet_button'));
      await tester.ensureVisible(saveButton);
      await pumpApp(tester);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('unified_pet_tile_buddy')),
        findsOneWidget,
        reason: 'Should show Buddy in the list',
      );
    });
  });
}
