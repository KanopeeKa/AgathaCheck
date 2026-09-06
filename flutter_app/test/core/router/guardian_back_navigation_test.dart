/// Task 31 – Guardian back-navigation journey proof.
///
/// Asserts real navigation-history behavior for the vet journey:
///
///   Journey A (list → detail → back):
///     1. Deep-link to /g/vets (list).
///     2. Tap a vet row  → GoRouter navigates to the nested child
///        /g/vets/:id, which pushes onto the Navigator stack.
///     3. Tap the shell back button (key 'experience_back_button').
///     4. Navigator.canPop is true (history exists), so Navigator.pop fires
///        and restores /g/vets.
///
///   Journey B (detail → edit → back):
///     1. Deep-link to /g/vets/:id (detail, already on-screen).
///     2. Tap 'Edit vet' button → context.go('/pc/vets/edit/:id').
///     3. Tap the VetFormScreen back arrow.
///     4. VetFormScreen.back always calls context.go(listPath) → /g/vets.
///
/// Uses real production route tables (buildVetExperienceRoutes) + real
/// ExperienceShellScaffold / VetListScreen / VetDetailScreen / VetFormScreen
/// with mocked providers – no reimplemented widgets.
library guardian_back_navigation_test;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/router/vet_routes.dart'
    show buildVetExperienceRoutes;
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/sharing/presentation/providers/sharing_providers.dart';
import 'package:pet_profile_app/features/subscription/data/services/revenuecat_service.dart';
import 'package:pet_profile_app/features/subscription/domain/entities/subscription_status.dart';
import 'package:pet_profile_app/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_my_vets_section.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

// ---------------------------------------------------------------------------
// Test vet fixture
// ---------------------------------------------------------------------------
const _testVet = Vet(id: 'vet-back-1', name: 'Dr Back');

// ---------------------------------------------------------------------------
// VetListNotifier that serves one real vet so the list row is tappable.
// ---------------------------------------------------------------------------
class _TestVetListNotifier extends VetListNotifier {
  @override
  Future<List<Vet>> build() async => const [_testVet];
}

// ---------------------------------------------------------------------------
// Fake RevenueCatService – avoids native SDK init.
// ---------------------------------------------------------------------------
class _FakeRevenueCatService implements RevenueCatService {
  @override
  bool get isInitialized => true;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> login(String userId) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<SubscriptionStatus> getSubscriptionStatus() async =>
      SubscriptionStatus.free;
  @override
  Future<List<Offering>> getOfferings() async => [];
  @override
  Future<SubscriptionStatus> purchasePackage(Package package) async =>
      SubscriptionStatus.free;
  @override
  Future<SubscriptionStatus> restorePurchases() async =>
      SubscriptionStatus.free;
  @override
  void addCustomerInfoListener(void Function(SubscriptionStatus) listener) {}
}

// ---------------------------------------------------------------------------
// Shared provider overrides
// ---------------------------------------------------------------------------
List<Override> _overrides(SharedPreferences prefs) => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  authProvider.overrideWith((ref) => FakeAuthNotifier()),
  experienceEligibilityProvider.overrideWith(
    (ref) => AsyncValue.data(
      ExperienceEligibilityRules.compute(
        pets: const [Pet(id: 'p0', name: 'T', species: 'cat')],
        orgMembershipCount: 0,
      ),
    ),
  ),
  combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
  guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
  orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
  petListProvider.overrideWith(TestPetListNotifier.new),
  vetListProvider.overrideWith(_TestVetListNotifier.new),
  organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
  healthEntriesNotifierProvider.overrideWith(() => FakeHealthEntriesNotifier()),
  notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
  pendingSharesProvider.overrideWith(() => FakePendingSharesNotifier()),
  revenueCatServiceProvider.overrideWithValue(_FakeRevenueCatService()),
  analyticsRouteObserverProvider.overrideWith(
    (_) => AnalyticsRouteObserver((_) {}),
  ),
];

// ---------------------------------------------------------------------------
// Router factory – uses only the real vet route table, plus the minimal
// additional route needed so the shell scaffold can navigate to /g/home.
// ---------------------------------------------------------------------------
GoRouter _router({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ...buildVetExperienceRoutes(),
      GoRoute(
        path: '/pc/home',
        builder: (_, __) => const Scaffold(body: PetCareMyVetsSection()),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(body: Text('not-found:${state.uri}')),
  );
}

Widget _app({required GoRouter router, required SharedPreferences prefs}) {
  return ProviderScope(
    overrides: _overrides(prefs),
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

// Pump until providers settle without hanging on infinite spinners.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 150));
}

// ===========================================================================
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // -------------------------------------------------------------------------
  // Journey A: list → (tap vet row) → detail → (tap shell back) → list
  // -------------------------------------------------------------------------
  group('Journey A: /g/vets → /g/vets/:id → back → /g/vets', () {
    testWidgets('tapping vet row navigates to detail (nested child push)', (
      tester,
    ) async {
      final router = _router(initialLocation: '/pc/vets');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      // List is rendered; vet row for 'Dr Back' must be present.
      expect(find.text('Dr Back'), findsOneWidget);

      // Tap the vet row — VetListScreen calls context.go('/pc/vets/vet-back-1').
      await tester.tap(find.text('Dr Back'));
      await _settle(tester);

      // Router is now at the child route /g/vets/vet-back-1.
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/vet-back-1',
      );
    });

    testWidgets('shell back button on detail pops to /g/vets', (tester) async {
      final router = _router(initialLocation: '/pc/vets');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      // Tap vet row to navigate to detail.
      await tester.tap(find.text('Dr Back'));
      await _settle(tester);

      // Confirm we're on detail.
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/vet-back-1',
      );

      // The shell scaffold shows the back button (non-root path).
      // Two ExperienceShellScaffolds are in-tree (list underneath, detail on
      // top) because GoRouter keeps the parent route mounted. Tap the last
      // (topmost / visible) one.
      final backButtons = find.byKey(const Key('experience_back_button'));
      expect(backButtons, findsWidgets);

      // Tap it.  Navigator.canPop should be true (child route was pushed),
      // so Navigator.pop fires and the router reverts to /g/vets.
      await tester.tap(backButtons.last);
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/pc/vets');
    });
  });

  // -------------------------------------------------------------------------
  // Journey B: /g/vets/:id → (tap edit) → /g/vets/edit/:id → (back) → /g/vets
  // -------------------------------------------------------------------------
  group('Journey B: /g/vets/:id → edit → back → /g/vets', () {
    testWidgets('edit button from detail navigates to /g/vets/edit/:id', (
      tester,
    ) async {
      // Deep-link straight to detail (simulates browser/push deep link).
      final router = _router(initialLocation: '/pc/vets/vet-back-1');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      // Confirm detail rendered (not an error page).
      expect(find.textContaining('not-found:'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/vet-back-1',
      );

      // Tap 'Edit care team' from the options menu.
      await tester.tap(find.byKey(const Key('care_team_options_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('care_team_edit_menu_item')));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/edit/vet-back-1',
      );
    });

    testWidgets('VetFormScreen back arrow navigates to /g/vets (listPath)', (
      tester,
    ) async {
      // Start on detail, navigate to edit, then tap back.
      final router = _router(initialLocation: '/pc/vets/vet-back-1');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      // Go to edit via care team options menu.
      await tester.tap(find.byKey(const Key('care_team_options_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('care_team_edit_menu_item')));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/edit/vet-back-1',
      );

      // VetFormScreen renders its own AppBar with an arrow_back icon whose
      // tooltip is 'Back to veterinarians' and whose onPressed calls
      // context.go(widget.listPath) = '/pc/vets'.
      // The shell scaffold on the detail screen also has an arrow_back, so
      // we locate by tooltip to disambiguate.
      final backArrow = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Back to veterinarians',
      );
      expect(backArrow, findsOneWidget);
      await tester.tap(backArrow);
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/pc/vets');
    });

    testWidgets('deep-linked edit page back arrow also navigates to /g/vets', (
      tester,
    ) async {
      // Deep-link directly to edit (e.g. from a notification or bookmark).
      final router = _router(initialLocation: '/pc/vets/edit/vet-back-1');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(find.textContaining('not-found:'), findsNothing);

      // No Navigator history exists from a cold deep-link, but
      // VetFormScreen.back always does context.go(listPath), not Navigator.pop,
      // so the result is identical whether or not history exists.
      final backArrow = find.byWidgetPredicate(
        (w) => w is IconButton && w.tooltip == 'Back to veterinarians',
      );
      expect(backArrow, findsOneWidget);
      await tester.tap(backArrow);
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/pc/vets');
    });
  });

  // -------------------------------------------------------------------------
  // Journey C: dashboard → (tap vet card) → detail → (tap shell back) → home
  // -------------------------------------------------------------------------
  group('Journey C: /g/home → /g/vets/:id → back → /g/home', () {
    testWidgets('shell back from dashboard-opened vet detail returns home', (
      tester,
    ) async {
      final router = _router(initialLocation: '/pc/home');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('care_team_card_vet-back-1')));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pc/vets/vet-back-1',
      );
      expect(
        router
            .routerDelegate
            .currentConfiguration
            .uri
            .queryParameters['returnTo'],
        '/pc/home',
      );

      final backButtons = find.byKey(const Key('experience_back_button'));
      expect(backButtons, findsOneWidget);
      await tester.tap(backButtons);
      await _settle(tester);

      expect(router.routerDelegate.currentConfiguration.uri.path, '/pc/home');
    });
  });
}
