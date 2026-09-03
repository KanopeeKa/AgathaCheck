import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/widgets/app_logo_title.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_navigation_rail.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_navigation_sidebar.dart';
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
  Size? viewport,
  String? screenTitle,
}) {
  final shell = ExperienceShellScaffold(
    experience: experience,
    currentLocation: currentLocation,
    screenTitle: screenTitle,
    child: const SizedBox.shrink(),
  );

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
      home: viewport == null
          ? shell
          : MediaQuery(
              data: MediaQueryData(size: viewport),
              child: shell,
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
        path: '/pc/home',
        builder: (context, state) => ExperienceShellScaffold(
          experience: AppExperience.petCare,
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
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: ExperienceShellScaffold(
              experience: AppExperience.petCare,
              currentLocation: '/pc/home',
              screenTitle: 'My Pets dashboard',
              child: const SizedBox.shrink(),
            ),
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
            experience: AppExperience.petCare,
            currentLocation: '/pc/pets',
            screenTitle: 'All pets',
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
        experience: AppExperience.petCare,
        currentLocation: '/pc/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_toggle')),
      findsOneWidget,
    );
    expect(find.text('Pet Care'), findsOneWidget);
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

  testWidgets('non-root path shows back arrow and workspace toggle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.petCare,
        currentLocation: '/pc/events',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_workspace_toggle')), findsOneWidget);
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
        experience: AppExperience.petCare,
        currentLocation: '/pc/home',
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
        experience: AppExperience.petCare,
        currentLocation: '/pc/home',
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
        experience: AppExperience.petCare,
        currentLocation: '/pc/home',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_nav_home')), findsNothing);
  });

  testWidgets('guardian root always reveals Shelter in workspace menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.petCare,
        currentLocation: '/pc/home',
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

  testWidgets('workspace toggle navigates to Shelter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWorkspaceRouterApp(prefs: prefs, initialLocation: '/pc/home'),
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
  });

  testWidgets('workspace toggle navigates to Pet Care', (
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
  });

  testWidgets('baseline: org non-root path shows back button', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        prefs: prefs,
        experience: AppExperience.organization,
        currentLocation: '/o/events',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
    expect(find.byKey(const Key('experience_workspace_toggle')), findsOneWidget);
    expect(find.byKey(const Key('experience_settings_menu')), findsNothing);
  });

  group('Guardian navigation rail (600–839px)', () {
    testWidgets('shows rail and hides bottom nav at 720px width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(720, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(720, 900),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('guardian_navigation_rail')), findsOneWidget);
      expect(find.byKey(const Key('guardian_bottom_navigation')), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('hides drawer when rail is visible', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(720, 900),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });

    testWidgets(
      'relocates workspace toggle to rail leading slot on section root',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(720, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(
            prefs: prefs,
            experience: AppExperience.petCare,
            currentLocation: '/pc/home',
            viewport: const Size(720, 900),
          ),
        );
        await tester.pumpAndSettle();

        final rail = find.byKey(const Key('guardian_navigation_rail'));
        expect(
          find.descendant(
            of: rail,
            matching: find.byKey(const Key('experience_workspace_toggle')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: rail,
            matching: find.bySemanticsLabel('AgathaTrack'),
          ),
          findsOneWidget,
        );
        expect(find.text('AgathaTrack'), findsNothing);
        expect(
          find.byKey(const Key('experience_workspace_toggle')),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows compact rail brand without duplicating app bar title', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(720, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(720, 900),
          screenTitle: 'AgathaTrack',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AgathaTrack'), findsNothing);
      final rail = find.byKey(const Key('guardian_navigation_rail'));
      expect(
        find.descendant(
          of: rail,
          matching: find.bySemanticsLabel('AgathaTrack'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps drawer available below 600px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNotNull);
    });

    testWidgets(
      'shows sidebar and hides drawer at expanded breakpoint (840px)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(840, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(
            prefs: prefs,
            experience: AppExperience.petCare,
            currentLocation: '/pc/home',
            viewport: const Size(840, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('guardian_navigation_sidebar')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('guardian_navigation_rail')), findsNothing);
        expect(
          find.byKey(const Key('guardian_bottom_navigation')),
          findsNothing,
        );
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.drawer, isNull);
      },
    );

    testWidgets('uses Row layout with rail and content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
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
            home: MediaQuery(
              data: const MediaQueryData(size: Size(720, 900)),
              child: ExperienceShellScaffold(
                experience: AppExperience.petCare,
                currentLocation: '/pc/home',
                child: const Center(child: Text('Rail content')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Rail content'), findsOneWidget);
      expect(find.byType(GuardianNavigationRail), findsOneWidget);
    });
  });

  group('Guardian navigation sidebar (≥840px)', () {
    testWidgets(
      'shows sidebar with primary destinations and footer Account at 1024px',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(
            prefs: prefs,
            experience: AppExperience.petCare,
            currentLocation: '/pc/home',
            viewport: const Size(1024, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('guardian_navigation_sidebar')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('guardian_navigation_rail')), findsNothing);
        expect(
          find.byKey(const Key('guardian_bottom_navigation')),
          findsNothing,
        );
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Pets'), findsOneWidget);
        expect(find.text('Actions'), findsOneWidget);
        expect(find.text('Fostering'), findsOneWidget);
        expect(find.text('Account'), findsOneWidget);
      },
    );

    testWidgets('shows AgathaTrack once on section root at 1024px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

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
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1024, 900)),
              child: ExperienceShellScaffold(
                experience: AppExperience.petCare,
                currentLocation: '/pc/home',
                screenTitle: 'AgathaTrack',
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AgathaTrack'), findsOneWidget);
      expect(
        find.byKey(const Key('experience_notification_bell')),
        findsOneWidget,
      );
    });

    testWidgets('sidebar width is ~240px at 1024px', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(1024, 900),
        ),
      );
      await tester.pumpAndSettle();

      final sidebarSize = tester.getSize(
        find.byKey(const Key('guardian_navigation_sidebar')),
      );
      expect(sidebarSize.width, GuardianNavigationSidebar.width);
    });

    testWidgets('hides drawer when sidebar is visible', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildApp(
          prefs: prefs,
          experience: AppExperience.petCare,
          currentLocation: '/pc/home',
          viewport: const Size(1024, 900),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNull);
    });

    testWidgets(
      'relocates workspace toggle to sidebar header on section root',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(
            prefs: prefs,
            experience: AppExperience.petCare,
            currentLocation: '/pc/home',
            viewport: const Size(1024, 900),
          ),
        );
        await tester.pumpAndSettle();

        final sidebar = find.byKey(const Key('guardian_navigation_sidebar'));
        expect(
          find.descendant(
            of: sidebar,
            matching: find.byKey(const Key('experience_workspace_toggle')),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('experience_workspace_toggle')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows back button on non-root with workspace toggle in sidebar',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _buildApp(
            prefs: prefs,
            experience: AppExperience.petCare,
            currentLocation: '/pc/events',
            viewport: const Size(1024, 900),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('experience_back_button')), findsOneWidget);
        expect(
          find.byKey(const Key('experience_workspace_toggle')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses left-aligned page title instead of AppLogoTitle at 1024px',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1024, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

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
              home: MediaQuery(
                data: const MediaQueryData(size: Size(1024, 900)),
                child: ExperienceShellScaffold(
                  experience: AppExperience.petCare,
                  currentLocation: '/pc/pets',
                  screenTitle: 'All pets',
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All pets'), findsOneWidget);
        expect(
          find.byKey(const Key('experience_content_chrome')),
          findsOneWidget,
        );
        expect(find.byType(AppBar), findsNothing);
        final chrome = tester.widget<Material>(
          find.byKey(const Key('experience_content_chrome')),
        );
        expect(chrome.color, AppColorTokens.background);
      },
    );

    testWidgets('uses Row layout with sidebar and content at 1024px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
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
            home: MediaQuery(
              data: const MediaQueryData(size: Size(1024, 900)),
              child: ExperienceShellScaffold(
                experience: AppExperience.petCare,
                currentLocation: '/pc/home',
                child: const Center(child: Text('Sidebar content')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Sidebar content'), findsOneWidget);
      expect(find.byType(GuardianNavigationSidebar), findsOneWidget);
    });
  });
}
