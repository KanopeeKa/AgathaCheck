import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/router/app_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

void main() {
  group('Pet Profile Integration Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      // ignore: invalid_use_of_visible_for_testing_member
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
            );
          },
        ),
      );
    }

    testWidgets('shows empty state initially', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(find.text('No pets yet!'), findsOneWidget);
      expect(find.text('Add Pet'), findsOneWidget);
    });

    testWidgets('navigates to add pet form', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Pet'));
      await tester.pumpAndSettle();

      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Species *'), findsOneWidget);
      expect(find.text('Save Pet'), findsOneWidget);
    });

    testWidgets('validates required name field', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Pet'));
      await tester.pumpAndSettle();

      final saveButton = find.text('Save Pet');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text("Please enter the pet's name"), findsOneWidget);
    });

    testWidgets('adds a pet and shows it in list', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Pet'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Buddy');

      final saveButton = find.text('Save Pet');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Buddy'), findsOneWidget);
    });
  });
}
