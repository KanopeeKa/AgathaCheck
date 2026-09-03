import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_workspace_toggle.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildToggle({
  required SharedPreferences prefs,
  required String currentLocation,
  bool showShelter = false,
  bool onDarkBackground = false,
}) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExperienceWorkspaceToggle(
          currentLocation: currentLocation,
          onDarkBackground: onDarkBackground,
          showShelter: showShelter,
        ),
      ),
    ),
  );
}

Widget _buildWorkspaceRouterApp({
  required SharedPreferences prefs,
  required String initialLocation,
  bool showShelter = true,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/pc/home',
        builder: (context, state) => Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExperienceWorkspaceToggle(
                currentLocation: state.uri.path,
                onDarkBackground: false,
                showShelter: showShelter,
              ),
              const Text('Guardian home'),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/o/orgs',
        builder: (context, state) => Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExperienceWorkspaceToggle(
                currentLocation: state.uri.path,
                onDarkBackground: false,
                showShelter: showShelter,
              ),
              const Text('Shelter orgs'),
            ],
          ),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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

  testWidgets('opens workspace menu on tap', (tester) async {
    await tester.pumpWidget(
      _buildToggle(
        prefs: prefs,
        currentLocation: '/pc/home',
        showShelter: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_menu_guardian')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('experience_workspace_menu_shelter')),
      findsOneWidget,
    );
  });

  testWidgets('shows both workspace options without clipping', (tester) async {
    await tester.pumpWidget(
      _buildToggle(
        prefs: prefs,
        currentLocation: '/pc/home',
        showShelter: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();

    final menuCard = find.descendant(
      of: find.byType(Overlay),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Material &&
            widget.type == MaterialType.card &&
            widget.color == AppColorTokens.petCarePrimary,
      ),
    );
    expect(tester.getSize(menuCard).height, greaterThan(48));

    final guardianItem = find.byKey(
      const Key('experience_workspace_menu_guardian'),
    );
    final shelterItem = find.byKey(
      const Key('experience_workspace_menu_shelter'),
    );
    expect(
      tester.getCenter(shelterItem).dy,
      greaterThan(tester.getCenter(guardianItem).dy),
    );
  });

  testWidgets('hides Shelter when showShelter is false', (tester) async {
    await tester.pumpWidget(
      _buildToggle(
        prefs: prefs,
        currentLocation: '/pc/home',
        showShelter: false,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('experience_workspace_toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('experience_workspace_menu_guardian')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('experience_workspace_menu_shelter')),
      findsNothing,
    );
  });

  testWidgets('selecting Shelter navigates to /o/orgs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildWorkspaceRouterApp(
        prefs: prefs,
        initialLocation: '/pc/home',
        showShelter: true,
      ),
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

    expect(find.text('Shelter orgs'), findsOneWidget);
  });

  testWidgets('selecting Pet Care navigates to /pc/home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildWorkspaceRouterApp(
        prefs: prefs,
        initialLocation: '/o/orgs',
        showShelter: true,
      ),
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

  testWidgets('keeps visual pill near 32px while hit target is at least 48px', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildToggle(prefs: prefs, currentLocation: '/pc/home'),
    );
    await tester.pumpAndSettle();

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
  });
}
