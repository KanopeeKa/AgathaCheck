import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
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

  Widget buildApp({ExperienceEligibility? eligibility}) {
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
        activeExperienceProvider.overrideWith((ref) => AppExperience.guardian),
        resolvedExperienceProvider.overrideWith(
          (ref) => AppExperience.guardian,
        ),
      ],
      child: MaterialApp.router(
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
    expect(find.byKey(const Key('account_my_details')), findsOneWidget);
    expect(find.byKey(const Key('account_sign_out')), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
  });

  testWidgets('account hides preferences for guardian-only users', (
    tester,
  ) async {
    final guardianOnly = ExperienceEligibilityRules.compute(
      pets: const [],
      orgMembershipCount: 0,
    );

    await tester.pumpWidget(buildApp(eligibility: guardianOnly));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('default_experience_guardian')), findsNothing);
    expect(find.text('Preferences'), findsOneWidget);
  });
}
