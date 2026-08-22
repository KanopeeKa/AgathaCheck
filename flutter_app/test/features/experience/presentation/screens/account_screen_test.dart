import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/account_screen.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp({ExperienceEligibility? eligibility, double textScale = 1}) {
    final resolvedEligibility =
        eligibility ??
        ExperienceEligibilityRules.compute(
          pets: const [
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

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        experienceEligibilityProvider.overrideWith(
          (ref) => AsyncValue.data(resolvedEligibility),
        ),
        combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
        guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
        orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
        organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        // removed activeExperienceProvider mock
        // removed resolvedExperienceProvider mock
      ],
      child: MaterialApp.router(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/account',
              builder: (context, state) => const AccountScreen(),
            ),
          ],
          initialLocation: '/account',
        ),
      ),
    );
  }

  testWidgets('account screen uses shell hamburger and section rows', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_settings_menu')), findsOneWidget);
    expect(find.byKey(const Key('account_hamburger')), findsNothing);
    expect(find.byKey(const Key('account_identity_summary')), findsOneWidget);
    expect(find.byKey(const Key('account_my_details')), findsOneWidget);
    expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets(
    'account shows show-organisation toggle for guardian-only users',
    (tester) async {
      final guardianOnly = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 0,
      );

      await tester.pumpWidget(buildApp(eligibility: guardianOnly));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('show_organisation_section_toggle')),
        findsOneWidget,
      );
      expect(find.text('Preferences'), findsOneWidget);
    },
  );

  testWidgets(
    'account landing remains usable at narrow width with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildApp(textScale: 2));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('account_identity_summary')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('account_sign_out')),
        200,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const Key('account_sign_out'))).bottom,
        lessThanOrEqualTo(700),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
