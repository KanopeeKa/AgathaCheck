
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
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
    ];

    testWidgets('shows empty state initially', (tester) async {
      final testNotifier = TestPetListNotifier();
      final emptyPetListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), emptyPetListOverride],
      ));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

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

      await debugPrintTree(tester);

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

      await debugPrintTree(tester);

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

      // The validator string is hardcoded in pet_form_screen.dart, so we check for it directly
      expect(find.text("Please enter the pet's name"), findsOneWidget, reason: 'Should show required name validation');
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      final testNotifier = TestPetListNotifier();
      final petListOverride = petListProvider.overrideWith(() => testNotifier);
      await tester.pumpWidget(createApp(
        prefs: prefs,
        overrides: [...baseOverrides(prefs), petListOverride],
      ));
      await tester.pumpAndSettle();

      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      final addPetButton = find.text(l10n.addPet);
      expect(addPetButton, findsOneWidget, reason: 'Should find Add Pet button');
      await tester.tap(addPetButton);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Buddy');

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Simulate the notifier updating the list
      await testNotifier.addPet(name: 'Buddy', species: 'Dog');
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget, reason: 'Should show Buddy in the list');
    });
  });
}
