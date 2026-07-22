import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_settings_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {required List<Override> overrides}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dualEligibility = ExperienceEligibilityRules.compute(
    pets: const [
      Pet(id: '1', name: 'A', species: 'Cat'),
      Pet(
        id: '2',
        name: 'B',
        species: 'Dog',
        organizationId: 'o1',
        organizationName: 'Shelter',
      ),
    ],
    orgMembershipCount: 1,
  );

  group('ExperienceSettingsSection', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('shows default experience radios for dual-role users', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ExperienceSettingsSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            experienceEligibilityProvider.overrideWith(
              (ref) => AsyncValue.data(dualEligibility),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('default_experience_guardian')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('default_experience_organization')),
        findsOneWidget,
      );
      expect(find.text('Default experience'), findsOneWidget);
    });

    testWidgets('updates selected radio when default experience changes', (
      tester,
    ) async {
      await prefs.setString(
        'experience_default',
        AppExperience.organization.wire,
      );

      await tester.pumpWidget(
        _wrap(
          const ExperienceSettingsSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            experienceEligibilityProvider.overrideWith(
              (ref) => AsyncValue.data(dualEligibility),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      RadioListTile<AppExperience> radioTile(WidgetTester t, String wire) {
        return t.widget<RadioListTile<AppExperience>>(
          find.byKey(Key('default_experience_$wire')),
        );
      }

      expect(
        radioTile(tester, AppExperience.organization.wire).groupValue,
        AppExperience.organization,
      );

      await tester.tap(
        find.byKey(Key('default_experience_${AppExperience.guardian.wire}')),
      );
      await tester.pumpAndSettle();

      expect(
        radioTile(tester, AppExperience.guardian.wire).groupValue,
        AppExperience.guardian,
      );
      expect(
        radioTile(tester, AppExperience.organization.wire).groupValue,
        AppExperience.guardian,
      );
    });

    testWidgets('hides section for guardian-only users', (tester) async {
      final guardianOnly = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 0,
      );
      await tester.pumpWidget(
        _wrap(
          const ExperienceSettingsSection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            experienceEligibilityProvider.overrideWith(
              (ref) => AsyncValue.data(guardianOnly),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('default_experience_guardian')),
        findsNothing,
      );
      expect(find.text('Default experience'), findsNothing);
    });
  });
}
