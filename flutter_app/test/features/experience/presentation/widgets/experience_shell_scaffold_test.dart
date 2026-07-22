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

class _FosterOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'o1',
      name: 'Shelter',
      type: OrganizationType.charity,
      role: 'foster',
    ),
  ];
}

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

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

  final guardianOnlyEligibility = ExperienceEligibilityRules.compute(
    pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
    orgMembershipCount: 0,
  );

  testWidgets('guardian shell shows home and events nav keys', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(dualEligibility),
          ),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
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

  testWidgets('org shell hides events from top nav', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(dualEligibility),
          ),
          orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
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
            experience: AppExperience.organization,
            currentLocation: '/o/home',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_nav_home')), findsOneWidget);
    expect(find.byKey(const Key('experience_nav_events')), findsNothing);
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
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
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
    expect(find.byKey(const Key('drawer_create_organisation')), findsOneWidget);
  });

  testWidgets('guardian drawer always shows create organisation entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(guardianOnlyEligibility),
          ),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
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

    expect(find.byKey(const Key('drawer_create_organisation')), findsOneWidget);
    expect(find.byKey(const Key('drawer_org_view')), findsNothing);
  });

  testWidgets('org drawer lists organisations and my pets for foster portal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          organizationListProvider.overrideWith(_FosterOrgListNotifier.new),
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(
              ExperienceEligibilityRules.compute(
                pets: const [
                  Pet(
                    id: '2',
                    name: 'B',
                    species: 'Dog',
                    organizationId: 'o1',
                    organizationName: 'Shelter',
                    isFoster: true,
                  ),
                ],
                orgMembershipCount: 1,
              ),
            ),
          ),
          orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 2),
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
            experience: AppExperience.organization,
            currentLocation: '/o/home',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_settings_menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawer_org_o1')), findsOneWidget);
    expect(find.text('Shelter'), findsOneWidget);
    expect(find.byKey(const Key('drawer_my_pets')), findsOneWidget);
    expect(find.byKey(const Key('drawer_org_events')), findsOneWidget);
    expect(find.byKey(const Key('drawer_invite')), findsNothing);
  });
}
