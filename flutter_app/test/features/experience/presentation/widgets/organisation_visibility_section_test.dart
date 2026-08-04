import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/organisation_visibility_section.dart';
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

  group('OrganisationVisibilitySection', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('non-member toggle off by default and can enable', (
      tester,
    ) async {
      final guardianOnly = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 0,
      );

      await tester.pumpWidget(
        _wrap(
          const OrganisationVisibilitySection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            experienceEligibilityProvider.overrideWith(
              (ref) => AsyncValue.data(guardianOnly),
            ),
            hasOrgMembershipProvider.overrideWith((ref) => false),
            showOrganisationSectionPrefProvider.overrideWith((ref) => false),
            showOrganisationSectionProvider.overrideWith((ref) => false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('show_organisation_section_toggle')),
      );
      expect(toggle.value, isFalse);
      expect(toggle.onChanged, isNotNull);

      await tester.tap(
        find.byKey(const Key('show_organisation_section_toggle')),
      );
      await tester.pumpAndSettle();

      expect(prefs.getBool('show_organisation_section'), isTrue);
    });

    testWidgets('member toggle on, disabled, shows locked explanation', (
      tester,
    ) async {
      final dual = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 1,
      );

      await tester.pumpWidget(
        _wrap(
          const OrganisationVisibilitySection(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            experienceEligibilityProvider.overrideWith(
              (ref) => AsyncValue.data(dual),
            ),
            hasOrgMembershipProvider.overrideWith((ref) => true),
            showOrganisationSectionPrefProvider.overrideWith((ref) => false),
            showOrganisationSectionProvider.overrideWith((ref) => true),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const Key('show_organisation_section_toggle')),
      );
      expect(toggle.value, isTrue);
      expect(toggle.onChanged, isNull);
      expect(
        find.text(
          'Organisation stays visible because you belong to at least one organisation.',
        ),
        findsOneWidget,
      );
    });
  });
}
