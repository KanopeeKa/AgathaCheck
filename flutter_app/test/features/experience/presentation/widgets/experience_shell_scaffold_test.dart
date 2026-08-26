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
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

/// Builds a test app wrapping [ExperienceShellScaffold] with minimal overrides.
Widget _buildApp({
  required SharedPreferences prefs,
  required AppExperience experience,
  required String currentLocation,
  int combinedUnread = 0,
  bool showOrganisationSection = false,
}) {
  if (showOrganisationSection) {
    prefs.setBool('show_organisation_section', true);
  }

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      experienceEligibilityProvider.overrideWith(
        (ref) => AsyncValue.data(
          ExperienceEligibilityRules.compute(
            pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
            orgMembershipCount: 0,
          ),
        ),
      ),
      showOrganisationSectionProvider.overrideWith(
        (ref) => showOrganisationSection,
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
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
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

Widget _buildWorkspaceRouterApp({
  required SharedPreferences prefs,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/g/home',
        builder: (context, state) => ExperienceShellScaffold(
          experience: AppExperience.guardian,
          currentLocation: state.uri.path,
          child: const Center(child: Text('Guardian home')),
        ),
      ),
      GoRoute(
        path: '/o/orgs',
        builder: (context, state) => ExperienceShellScaffold(
          experience: AppExperience.organization,
          currentLocation: state.uri.path,
          child: const Center(child: Text('Shelter home')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      showOrganisationSectionProvider.overrideWith((ref) => true),
      combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
      guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
      orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('section root shows centered logo title when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(
              ExperienceEligibilityRules.compute(
                pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
                orgMembershipCount: 0,
              ),
            ),
          ),
          showOrganisationSectionProvider.overrideWith((ref) => false),
          combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
          orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
            screenTitle: 'My Pets dashboard',
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Pets dashboard'), findsOneWidget);
  });

  testWidgets('contextual actions appear before divider and bell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          experienceEligibilityProvider.overrideWith(
            (ref) => AsyncValue.data(
              ExperienceEligibilityRules.compute(
                pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
                orgMembershipCount: 0,
              ),
            ),
          ),
          showOrganisationSectionProvider.overrideWith((ref) => false),
          combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
          guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
          orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        ],
        child: MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ExperienceShellScaffold(
            experience: AppExperience.guardian,
            currentLocation: '/g/pets',
            screenTitle: 'All Pets',
            contextualActions: [
              IconButton(
                key: const Key('contextual_test_action'),
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
              ),
            ],
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('contextual_test_action')), findsOneWidget);
    expect(find.text('|'), findsNothing);
    expect(find.byType(VerticalDivider), findsOneWidget);
    expect(
      find.byKey(const Key('experience_notification_bell')),
      findsOneWidget,
    );
  });

  testWidgets('section root shows workspace toggle, not back arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.guardian,
        currentLocation: '/g/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_toggle')),
      findsOneWidget,
    );
    expect(find.text('My Pets'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('experience_workspace_toggle')))
          .height,
      48,
    );
    expect(
      tester.getSize(find.byKey(const Key('experience_workspace_pill'))).height,
      32,
    );
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
    expect(find.byKey(const Key('experience_back_button')), findsNothing);
  });

  testWidgets('non-root path shows back arrow, not workspace toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.guardian,
        currentLocation: '/g/events',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_workspace_toggle')), findsNothing);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
  });

  testWidgets('org section root /o/orgs shows Shelter workspace button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.organization,
        currentLocation: '/o/orgs',
        showOrganisationSection: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_toggle')),
      findsOneWidget,
    );
    expect(find.text('Shelter'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
    expect(find.byKey(const Key('experience_back_button')), findsNothing);
  });

  testWidgets('baseline: bell is always visible on shell screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.guardian,
        currentLocation: '/g/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_notification_bell')),
      findsOneWidget,
    );
  });

  testWidgets('baseline: bell badge shows combined unread count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
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

  testWidgets('baseline: no Home button present (navigation reversal)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.guardian,
        currentLocation: '/g/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_nav_home')), findsNothing);
  });

  testWidgets('guardian root reveals Shelter when it is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.guardian,
        currentLocation: '/g/home',
        showOrganisationSection: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_menu_shelter')),
      findsOneWidget,
    );
  });

  testWidgets('workspace toggle navigates to Shelter and remembers it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWorkspaceRouterApp(prefs: prefs, initialLocation: '/g/home'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();
    final shelterItem = find.byKey(
      const Key('experience_workspace_menu_shelter'),
    );
    await tester.ensureVisible(shelterItem);
    await tester.tap(shelterItem);
    await tester.pumpAndSettle();

    expect(find.text('Shelter home'), findsOneWidget);
    expect(
      prefs.getString('last_app_section'),
      AppExperience.organization.wire,
    );
  });

  testWidgets('workspace toggle navigates to My Pets and remembers it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWorkspaceRouterApp(prefs: prefs, initialLocation: '/o/orgs'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();
    final guardianItem = find.byKey(
      const Key('experience_workspace_menu_guardian'),
    );
    await tester.ensureVisible(guardianItem);
    await tester.tap(guardianItem);
    await tester.pumpAndSettle();

    expect(find.text('Guardian home'), findsOneWidget);
    expect(prefs.getString('last_app_section'), AppExperience.guardian.wire);
  });

  testWidgets('baseline: org non-root path shows back button', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.organization,
        currentLocation: '/o/events',
        showOrganisationSection: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_workspace_toggle')), findsNothing);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
  });
}
