import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
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

  testWidgets('guardian shell shows home and events nav keys', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(dualEligibility),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExperienceShellScaffold(
            experience: AppExperience.guardian,
            currentLocation: '/g/home',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_nav_home')), findsOneWidget);
    expect(find.byKey(const Key('experience_nav_events')), findsOneWidget);
    expect(find.byKey(const Key('experience_settings_menu')), findsOneWidget);
  });

  testWidgets('drawer shows organisation view for dual-role guardian shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(dualEligibility),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExperienceShellScaffold(
            experience: AppExperience.guardian,
            currentLocation: '/g/home',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_settings_menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawer_org_view')), findsOneWidget);
  });
}
