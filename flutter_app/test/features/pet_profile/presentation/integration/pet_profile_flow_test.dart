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
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
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
      apiBaseUrlProvider.overrideWithValue('http://test.local'),
      authOverride,
      petsOverride,
      fakePetRepositoryOverride,
      vetListProvider.overrideWith(FakeVetListNotifier.new),
      organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
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
      await pumpApp(tester);

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
      await pumpApp(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await pumpApp(tester);

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
      await pumpApp(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await pumpApp(tester);

      final saveButton = find.byKey(const Key('save_pet_button'));
      await tester.ensureVisible(saveButton);
      await pumpApp(tester);
      await tester.tap(saveButton, warnIfMissed: false);
      await pumpApp(tester);

      expect(find.text(l10n.petNameRequired), findsOneWidget, reason: 'Should show required name validation');
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      final testNotifier = TestPetListNotifier();
      final petListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), petListOverride],
      ));
      await pumpApp(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      await tester.tap(find.text(l10n.addPet));
      await pumpApp(tester);

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
        find.byKey(const Key('pet_card_Buddy')),
        findsOneWidget,
        reason: 'Should show Buddy in the list',
      );
    });
  });
}
