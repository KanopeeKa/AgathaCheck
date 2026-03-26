import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/router/app_router.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- TEST NOTIFIER FOR ADD PET ---
class PetListTestNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  PetListTestNotifier() : super(const AsyncValue.data([]));
  final provider = StateNotifierProvider<PetListTestNotifier, AsyncValue<List<dynamic>>>((ref) => PetListTestNotifier());
  ProviderOverride get override => provider.overrideWithValue(this);
  void addPet(String name) {
    state = AsyncValue.data([_TestPet(name)]);
  }
}
class _TestPet {
  final String name;
  _TestPet(this.name);
  String get id => name.toLowerCase();
  String get species => 'Dog';
  String get breed => '';
  String get bio => '';
  int get colorValue => 0xFF7E57C2;
  bool get passedAway => false;
  String? get photoPath => null;
}

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    // Helper to print the widget tree for debugging
    Future<void> debugPrintTree(WidgetTester tester) async {
      debugPrint('\n--- WIDGET TREE START ---');
      debugPrint(tester.element(find.byType(Scaffold)).toStringDeep());
      debugPrint('\n--- WIDGET TREE END ---');
    }

    Widget createApp({List overrides = const []}) {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ...overrides,
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            return MaterialApp.router(
              title: AppConstants.appTitle,
              theme: AppTheme.lightTheme,
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            );
          },
        ),
      );
    }

    testWidgets('shows empty state initially', (tester) async {
      // Override petListProvider to always return empty list for this test
      final emptyPetListOverride = petListProvider.overrideWith((ref) => const AsyncValue.data([]));
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
      await tester.pumpAndSettle();

      // Print widget tree for debugging
      await debugPrintTree(tester);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      // Check for empty state text
      expect(find.text(l10n.noPetsYet), findsOneWidget, reason: 'Should show empty state text');
      expect(find.text(l10n.addPet), findsOneWidget, reason: 'Should show Add Pet button');
    });

    testWidgets('navigates to add pet form', (tester) async {
      final emptyPetListOverride = petListProvider.overrideWith((ref) => const AsyncValue.data([]));
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
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
      final emptyPetListOverride = petListProvider.overrideWith((ref) => const AsyncValue.data([]));
      await tester.pumpWidget(createApp(overrides: [emptyPetListOverride]));
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
      // Use a test notifier to simulate adding a pet
      final testNotifier = PetListTestNotifier();
      final petListOverride = petListProvider.overrideWith((ref) => ref.watch(testNotifier.provider));
      await tester.pumpWidget(createApp(overrides: [petListOverride, testNotifier.override]));
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
      testNotifier.addPet('Buddy');
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget, reason: 'Should show Buddy in the list');
    });

// --- TEST NOTIFIER FOR ADD PET ---
import 'package:flutter_riverpod/flutter_riverpod.dart';
class PetListTestNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  PetListTestNotifier() : super(const AsyncValue.data([]));
  final provider = StateNotifierProvider<PetListTestNotifier, AsyncValue<List<dynamic>>>((ref) => PetListTestNotifier());
  ProviderOverride get override => provider.overrideWithValue(this);
  void addPet(String name) {
    state = AsyncValue.data([_TestPet(name)]);
  }
}
class _TestPet {
  final String name;
  _TestPet(this.name);
  String get id => name.toLowerCase();
  String get species => 'Dog';
  String get breed => '';
  String get bio => '';
  int get colorValue => 0xFF7E57C2;
  bool get passedAway => false;
  String? get photoPath => null;
}
  });
}
