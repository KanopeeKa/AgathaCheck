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
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

/// Builds a test app wrapping [ExperienceShellScaffold] with minimal overrides.
Widget _buildApp({
  required AppExperience experience,
  required String currentLocation,
  int combinedUnread = 0,
}) {
  return ProviderScope(
    overrides: [
      experienceEligibilityProvider.overrideWith(
        (ref) => AsyncValue.data(
          ExperienceEligibilityRules.compute(
            pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
            orgMembershipCount: 0,
          ),
        ),
      ),
      combinedUnreadNotificationCountProvider.overrideWith(
        (ref) => combinedUnread,
      ),
      // Provide zero for legacy providers to satisfy any watchers
      guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
      orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
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
        experience: experience,
        currentLocation: currentLocation,
        child: const SizedBox.shrink(),
      ),
    ),
  );
}

void main() {
  testWidgets('section root shows hamburger, not back arrow', (tester) async {
    await tester.pumpWidget(
      _buildApp(experience: AppExperience.guardian, currentLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_settings_menu')), findsOneWidget);
    expect(find.byKey(const Key('experience_back_button')), findsNothing);
  });

  testWidgets('non-root path shows back arrow, not hamburger', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        experience: AppExperience.guardian,
        currentLocation: '/g/events',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
  });

  testWidgets('org section root /o/orgs shows hamburger', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        experience: AppExperience.organization,
        currentLocation: '/o/orgs',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_settings_menu')), findsOneWidget);
    expect(find.byKey(const Key('experience_back_button')), findsNothing);
  });

  testWidgets('bell is always visible on shell screens', (tester) async {
    await tester.pumpWidget(
      _buildApp(experience: AppExperience.guardian, currentLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_notification_bell')),
      findsOneWidget,
    );
  });

  testWidgets('bell badge shows combined unread count', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        experience: AppExperience.guardian,
        currentLocation: '/g/home',
        combinedUnread: 5,
      ),
    );
    await tester.pumpAndSettle();

    final bellButton = find.byKey(const Key('experience_notification_bell'));
    expect(
      find.descendant(of: bellButton, matching: find.text('5')),
      findsOneWidget,
    );
  });

  testWidgets('no Home button present (navigation reversal)', (tester) async {
    await tester.pumpWidget(
      _buildApp(experience: AppExperience.guardian, currentLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_nav_home')), findsNothing);
  });

  testWidgets('drawer shows Guardian, Organisation, Account items', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(experience: AppExperience.guardian, currentLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_settings_menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawer_guardian')), findsOneWidget);
    expect(find.byKey(const Key('drawer_organisation')), findsOneWidget);
    expect(find.byKey(const Key('drawer_account')), findsOneWidget);
  });

  testWidgets('drawer does not contain deprecated items', (tester) async {
    await tester.pumpWidget(
      _buildApp(experience: AppExperience.guardian, currentLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_settings_menu')));
    await tester.pumpAndSettle();

    // These items must not exist in the new unified drawer
    expect(find.byKey(const Key('drawer_my_pets')), findsNothing);
    expect(
      find.byKey(const Key('drawer_guardian_notifications')),
      findsNothing,
    );
    expect(find.byKey(const Key('drawer_org_notifications')), findsNothing);
    expect(find.byKey(const Key('drawer_guardian_events')), findsNothing);
    expect(find.byKey(const Key('drawer_settings')), findsNothing);
    expect(find.byKey(const Key('drawer_logout')), findsNothing);
  });

  testWidgets('org non-root path shows back button', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        experience: AppExperience.organization,
        currentLocation: '/o/events',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
  });
}
