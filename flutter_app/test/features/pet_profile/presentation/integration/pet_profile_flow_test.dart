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
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import '../../../../helpers/fakes.dart';
import '../../../../helpers/test_helpers.dart';


final fakePetRepositoryOverride = petRepositoryProvider.overrideWithValue(FakePetRepository());
final petsOverride = getAllPetsUseCaseProvider.overrideWith((ref) => FakeGetAllPets());
final authOverride = authProvider.overrideWith((ref) => FakeAuthNotifier());

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });


    List<Override> baseOverrides(SharedPreferences prefs) => [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authOverride,
      petsOverride,
      fakePetRepositoryOverride,
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
      healthEntriesNotifierProvider.overrideWith(() => FakeHealthEntriesNotifier()),
      notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
      notificationPreferencesProvider.overrideWith(() => FakeNotificationPreferencesNotifier()),
      pendingSharesProvider.overrideWith(() => FakePendingSharesNotifier()),
    ];

    testWidgets('shows empty state initially', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), emptyPetListOverride],
      ));
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      expect(find.text(l10n.noPetsYet), findsOneWidget, reason: 'Should show empty state text');
      expect(find.text(l10n.addPet), findsOneWidget, reason: 'Should show Add Pet button');
    });

    testWidgets('navigates to add pet form', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), emptyPetListOverride],
      ));
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n.petName), findsOneWidget, reason: 'Should show pet name field');
      expect(find.text(l10n.species), findsOneWidget, reason: 'Should show species field');
      expect(find.text(l10n.savePet), findsOneWidget, reason: 'Should show save pet button');
    });

    testWidgets('validates required name field', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), emptyPetListOverride],
      ));
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text(l10n.petNameRequired), findsOneWidget, reason: 'Should show required name validation');
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      final pet = Pet(
        id: 'buddy',
        name: 'Buddy',
        species: 'Dog',
        breed: '',
        bio: '',
        insurance: '',
        chipId: '',
        colorValue: 0xFF7E57C2,
        passedAway: false,
      );
      final petListOverride = petListProvider.overrideWith(() => TestPetListNotifier([pet]));
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authOverride,
          petsOverride,
          fakePetRepositoryOverride,
          petListOverride,
          healthEntriesNotifierProvider.overrideWith(() => FakeHealthEntriesNotifier()),
          notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
          notificationPreferencesProvider.overrideWith(() => FakeNotificationPreferencesNotifier()),
          pendingSharesProvider.overrideWith(() => FakePendingSharesNotifier()),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget, reason: 'Should show Buddy in the list');
    });
  });
}
