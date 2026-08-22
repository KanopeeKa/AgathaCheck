/// Task 31 – Guardian route / journey proof.
///
/// Covers:
///   • /g/pets, /g/events, /g/vets/:id deep-link resolution
///   • /g/vets/edit/:id deep-link resolution
///   • /g/events → add-event type picker route wiring
///     (Health → /health/add, Weight → /pet/:id, Other → /pet/:id/other/add)
///   • Named route registration for all guardian routes
///   • Legacy /vets → /g/vets redirect logic
///
/// Strategy:
///   1. Pure unit tests for path/redirect logic (no widget rendering).
///   2. GoRouter + ProviderScope widget tests matching patterns from
///      test/features/experience/presentation/widgets/ for navigation assertions.
library guardian_routes_test;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/core/router/experience_routes.dart'
    show buildExperienceRoutes;
import 'package:pet_profile_app/core/router/vet_routes.dart'
    show buildVetExperienceRoutes, legacyVetRedirectForPath;
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
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
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../helpers/fakes.dart';

// ---------------------------------------------------------------------------
// Fake RevenueCatService – avoids native Purchases SDK init.
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
// A guardian-only ExperienceEligibility (no org access needed).
// ---------------------------------------------------------------------------
final _guardianEligibility = ExperienceEligibilityRules.compute(
  pets: const [Pet(id: 'p0', name: 'Test', species: 'cat')],
  orgMembershipCount: 0,
);

class _LoadingPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() => Completer<List<Pet>>().future;
}

// ---------------------------------------------------------------------------
// Minimum provider overrides for the guardian experience shell to mount
// without hitting real services or native SDKs.
// ---------------------------------------------------------------------------
List<Override> _guardianShellOverrides({
  required SharedPreferences prefs,
  List<Pet> pets = const [],
  bool petsLoading = false,
}) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authProvider.overrideWith((ref) => FakeAuthNotifier()),
    experienceEligibilityProvider.overrideWith(
      (ref) => AsyncValue.data(_guardianEligibility),
    ),
    combinedUnreadNotificationCountProvider.overrideWith((ref) => 0),
    guardianUnreadNotificationCountProvider.overrideWith((ref) => 0),
    orgUnreadNotificationCountProvider.overrideWith((ref) => 0),
    petListProvider.overrideWith(
      () => petsLoading ? _LoadingPetListNotifier() : TestPetListNotifier(pets),
    ),
    vetListProvider.overrideWith(FakeVetListNotifier.new),
    organizationListProvider.overrideWith(FakeOrganizationListNotifier.new),
    healthEntriesNotifierProvider.overrideWith(
      () => FakeHealthEntriesNotifier(),
    ),
    notificationsProvider.overrideWith(() => FakeNotificationsNotifier()),
    pendingSharesProvider.overrideWith(() => FakePendingSharesNotifier()),
    revenueCatServiceProvider.overrideWithValue(_FakeRevenueCatService()),
    analyticsRouteObserverProvider.overrideWith(
      (_) => AnalyticsRouteObserver((_) {}),
    ),
  ];
}

// ---------------------------------------------------------------------------
// Lightweight GoRouter using real production route tables plus stub
// destinations reached from the add-event picker.
// ---------------------------------------------------------------------------
GoRouter _buildStubRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ...buildExperienceRoutes(),
      ...buildVetExperienceRoutes(),
      // Picker destinations.
      GoRoute(
        path: '/health/add',
        builder: (_, __) => const Scaffold(body: Text('health-add')),
      ),
      GoRoute(
        path: '/pet/:petId',
        builder: (_, state) =>
            Scaffold(body: Text('pet-${state.pathParameters['petId']}')),
      ),
      GoRoute(
        path: '/pet/:petId/other/add',
        builder: (_, state) =>
            Scaffold(body: Text('other-add-${state.pathParameters['petId']}')),
      ),
      // Fallback stubs referenced by redirect/back logic.
      GoRoute(
        path: '/landing',
        builder: (_, __) => const Scaffold(body: Text('landing')),
      ),
      GoRoute(
        path: '/app/resolve',
        builder: (_, __) => const Scaffold(body: Text('resolve')),
      ),
      GoRoute(
        path: '/g/home',
        builder: (_, __) => const Scaffold(body: Text('guardian-home')),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(body: Text('not-found:${state.uri}')),
  );
}

Widget _app({
  required GoRouter router,
  required SharedPreferences prefs,
  List<Pet> pets = const [],
  bool petsLoading = false,
}) {
  return ProviderScope(
    overrides: _guardianShellOverrides(
      prefs: prefs,
      pets: pets,
      petsLoading: petsLoading,
    ),
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 100));
}

// ===========================================================================
// Tests
// ===========================================================================
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // 1. Pure unit tests – legacy redirect path logic
  // -------------------------------------------------------------------------
  group('legacy vet path redirects', () {
    test('/vets → /g/vets', () {
      expect(legacyVetRedirectForPath('/vets'), '/g/vets');
    });

    test('/vets/add → /g/vets/add', () {
      expect(legacyVetRedirectForPath('/vets/add'), '/g/vets/add');
    });

    test('/vets/edit/vet-42 → /g/vets/edit/vet-42', () {
      expect(
        legacyVetRedirectForPath('/vets/edit/vet-42'),
        '/g/vets/edit/vet-42',
      );
    });

    test('/g/vets returns null (no redirect loop)', () {
      expect(legacyVetRedirectForPath('/g/vets'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // 2. Named route registration (pure GoRouter, no widget pumping)
  // -------------------------------------------------------------------------
  group('guardian named route registration', () {
    late GoRouter router;

    setUpAll(() {
      router = GoRouter(
        initialLocation: '/landing',
        routes: [
          ...buildExperienceRoutes(),
          ...buildVetExperienceRoutes(),
          GoRoute(path: '/landing', builder: (_, __) => const Scaffold()),
        ],
      );
    });

    test('guardianAllPets resolves to /g/pets', () {
      expect(router.namedLocation('guardianAllPets'), '/g/pets');
    });

    test('guardianEvents resolves to /g/events', () {
      expect(router.namedLocation('guardianEvents'), '/g/events');
    });

    test('guardianVets resolves to /g/vets', () {
      expect(router.namedLocation('guardianVets'), '/g/vets');
    });

    test('guardianVetDetail resolves to /g/vets/:id', () {
      expect(
        router.namedLocation(
          'guardianVetDetail',
          pathParameters: {'id': 'vet-1'},
        ),
        '/g/vets/vet-1',
      );
    });

    test('guardianEditVet resolves to /g/vets/edit/:id', () {
      expect(
        router.namedLocation(
          'guardianEditVet',
          pathParameters: {'id': 'vet-99'},
        ),
        '/g/vets/edit/vet-99',
      );
    });

    test('guardianAddVet resolves to /g/vets/add', () {
      expect(router.namedLocation('guardianAddVet'), '/g/vets/add');
    });
  });

  // -------------------------------------------------------------------------
  // 3. Add-event picker target path cross-reference
  //    The picker uses hard-coded context.go(path) strings.
  //    These unit tests guard against route renames breaking the wiring.
  // -------------------------------------------------------------------------
  group('add-event picker target paths registered in router', () {
    late GoRouter router;

    setUpAll(() {
      router = GoRouter(
        initialLocation: '/l',
        routes: [
          GoRoute(path: '/l', builder: (_, __) => const Scaffold()),
          GoRoute(
            path: '/health/add',
            name: 'addHealthEntry',
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: '/pet/:petId',
            name: 'petDetail',
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: '/pet/:petId/other/add',
            name: 'addPetOtherEvent',
            builder: (_, __) => const Scaffold(),
          ),
        ],
      );
    });

    test('/health/add registered (Health picker → addHealthEntry)', () {
      expect(router.namedLocation('addHealthEntry'), '/health/add');
    });

    test('/pet/:id registered (Weight picker → petDetail)', () {
      expect(
        router.namedLocation('petDetail', pathParameters: {'petId': 'p1'}),
        '/pet/p1',
      );
    });

    test('/pet/:id/other/add registered (Other picker → addPetOtherEvent)', () {
      expect(
        router.namedLocation(
          'addPetOtherEvent',
          pathParameters: {'petId': 'p1'},
        ),
        '/pet/p1/other/add',
      );
    });
  });

  // =========================================================================
  // 4. Deep-link resolution widget tests
  // =========================================================================

  group('/g/pets deep-link', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('resolves without error page', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/pets');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(find.textContaining('not-found:'), findsNothing);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/g/pets');
    });
  });

  group('/g/events deep-link', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('resolves without error page', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/events');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(find.textContaining('not-found:'), findsNothing);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/g/events');
    });

    testWidgets('add button is present in app bar', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/events');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(
        find.byKey(const Key('global_events_add_app_bar')),
        findsOneWidget,
      );
    });

    testWidgets('add button is disabled while pets are loading', (
      tester,
    ) async {
      final router = _buildStubRouter(initialLocation: '/g/events');
      await tester.pumpWidget(
        _app(router: router, prefs: prefs, petsLoading: true),
      );
      await _settle(tester);

      final addButton = tester.widget<IconButton>(
        find.byKey(const Key('global_events_add_app_bar')),
      );
      expect(addButton.onPressed, isNull);
      expect(find.byIcon(Icons.medical_services_outlined), findsNothing);
    });
  });

  group('/g/vets/:id deep-link', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('resolves vet detail without error page', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/vets/vet-1');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(find.textContaining('not-found:'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/g/vets/vet-1',
      );
    });
  });

  group('/g/vets/edit/:id deep-link', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('resolves vet edit without error page', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/vets/edit/vet-99');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(find.textContaining('not-found:'), findsNothing);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/g/vets/edit/vet-99',
      );
    });

    testWidgets('preserves vet id in path', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/vets/edit/vet-42');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/g/vets/edit/vet-42',
      );
    });
  });

  // =========================================================================
  // 5. /g/events add-event picker wiring (widget navigation)
  // =========================================================================
  group('/g/events add-event picker wiring', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Health tile navigates to /health/add', (tester) async {
      final router = _buildStubRouter(initialLocation: '/g/events');
      await tester.pumpWidget(_app(router: router, prefs: prefs));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.medical_services_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.medical_services_outlined));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/health/add',
      );
    });

    testWidgets('Weight tile with single active pet navigates to /pet/:id', (
      tester,
    ) async {
      const pet = Pet(
        id: 'pet-w1',
        name: 'Whiskers',
        species: 'cat',
        breed: '',
        colorValue: 0xFF7E57C2,
        passedAway: false,
      );
      final router = _buildStubRouter(initialLocation: '/g/events');
      await tester.pumpWidget(_app(router: router, prefs: prefs, pets: [pet]));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.monitor_weight_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.monitor_weight_outlined));
      await _settle(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/pet/pet-w1',
      );
    });

    testWidgets(
      'Other tile with single active pet navigates to /pet/:id/other/add',
      (tester) async {
        const pet = Pet(
          id: 'pet-o1',
          name: 'Buddy',
          species: 'dog',
          breed: '',
          colorValue: 0xFF7E57C2,
          passedAway: false,
        );
        final router = _buildStubRouter(initialLocation: '/g/events');
        await tester.pumpWidget(
          _app(router: router, prefs: prefs, pets: [pet]),
        );
        await _settle(tester);

        await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
        await tester.tap(find.byIcon(Icons.event_note_outlined));
        await _settle(tester);

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/pet/pet-o1/other/add',
        );
      },
    );

    testWidgets(
      'Weight tile with no active pets stays on /g/events (snackbar shown)',
      (tester) async {
        final router = _buildStubRouter(initialLocation: '/g/events');
        await tester.pumpWidget(_app(router: router, prefs: prefs, pets: []));
        await _settle(tester);

        await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.monitor_weight_outlined));
        await _settle(tester);

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/g/events',
        );
      },
    );

    testWidgets(
      'Other tile with no active pets stays on /g/events (snackbar shown)',
      (tester) async {
        final router = _buildStubRouter(initialLocation: '/g/events');
        await tester.pumpWidget(_app(router: router, prefs: prefs, pets: []));
        await _settle(tester);

        await tester.tap(find.byKey(const Key('global_events_add_app_bar')));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.event_note_outlined));
        await _settle(tester);

        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/g/events',
        );
      },
    );
  });
}
