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
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget createApp() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      expect(find.text(l10n.noPetsYet), findsOneWidget);
      expect(find.text(l10n.addPet), findsOneWidget);
    });

    testWidgets('navigates to add pet form', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      await tester.tap(find.text(l10n.addPet));
      await tester.pumpAndSettle();

      expect(find.text(l10n.petName), findsOneWidget);
      expect(find.text(l10n.species), findsOneWidget);
      expect(find.text(l10n.savePet), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      await tester.tap(find.text(l10n.addPet));
      await tester.pumpAndSettle();

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // The validator string is hardcoded in pet_form_screen.dart, so we check for it directly
      expect(find.text("Please enter the pet's name"), findsOneWidget);
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(scaffoldContext)!;

      await tester.tap(find.text(l10n.addPet));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Buddy');

      final saveButton = find.text(l10n.savePet);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget);
    });
  });
}
