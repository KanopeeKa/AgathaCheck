import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/my_details_screen.dart';
import '../../features/health_tracking/domain/entities/health_entry.dart';
import '../../features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import '../../features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_list_screen.dart';
import '../../features/sharing/presentation/screens/shared_pet_screen.dart';
import '../../features/subscription/presentation/screens/paywall_screen.dart';
import '../../features/vet/presentation/screens/vet_form_screen.dart';
import '../../features/vet/presentation/screens/vet_list_screen.dart';

class AuthChangeNotifier extends ChangeNotifier {
  AuthState _authState;

  AuthChangeNotifier(this._authState);

  void update(AuthState newState) {
    final wasLoggedIn = _authState.isLoggedIn;
    final isNowLoggedIn = newState.isLoggedIn;
    _authState = newState;
    if (wasLoggedIn != isNowLoggedIn) {
      notifyListeners();
    }
  }

  bool get isLoggedIn => _authState.isLoggedIn;
  bool get isLoading => _authState.isLoading;
  bool get hasToken => _authState.accessToken != null;
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier(ref.read(authProvider));
  ref.listen<AuthState>(authProvider, (_, next) {
    notifier.update(next);
  });
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final path = state.uri.path;

      if (authNotifier.isLoading && authNotifier.hasToken) {
        return null;
      }

      if (!isLoggedIn) {
        if (path == '/landing') return null;
        if (path == '/forgot-password') return null;
        if (path.startsWith('/shared/')) return null;
        return '/landing';
      }

      if (isLoggedIn && path == '/landing') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const PetListScreen(),
      ),
      GoRoute(
        path: '/my-details',
        name: 'myDetails',
        builder: (context, state) => const MyDetailsScreen(),
      ),
      GoRoute(
        path: '/add',
        name: 'addPet',
        builder: (context, state) => const PetFormScreen(),
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'editPet',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetFormScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pet/:petId',
        name: 'petDetail',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetDetailScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pet/:petId/health/add',
        name: 'addPetHealthEntry',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final typeParam = state.uri.queryParameters['type'];
          final initialType = typeParam != null
              ? HealthEntryType.values.where((t) => t.name == typeParam).firstOrNull
              : null;
          return HealthEntryFormScreen(petId: petId, initialType: initialType);
        },
      ),
      GoRoute(
        path: '/pet/:petId/health/edit/:id',
        name: 'editPetHealthEntry',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final entryId = state.pathParameters['id']!;
          return HealthEntryFormScreen(entryId: entryId, petId: petId);
        },
      ),
      GoRoute(
        path: '/health',
        name: 'healthDashboard',
        builder: (context, state) => const HealthDashboardScreen(),
      ),
      GoRoute(
        path: '/health/add',
        name: 'addHealthEntry',
        builder: (context, state) {
          final typeParam = state.uri.queryParameters['type'];
          final initialType = typeParam != null
              ? HealthEntryType.values.where((t) => t.name == typeParam).firstOrNull
              : null;
          return HealthEntryFormScreen(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/health/edit/:id',
        name: 'editHealthEntry',
        builder: (context, state) {
          final entryId = state.pathParameters['id']!;
          return HealthEntryFormScreen(entryId: entryId);
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notifications/settings',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/vets',
        name: 'vetList',
        builder: (context, state) => const VetListScreen(),
      ),
      GoRoute(
        path: '/vets/add',
        name: 'addVet',
        builder: (context, state) => const VetFormScreen(),
      ),
      GoRoute(
        path: '/vets/edit/:id',
        name: 'editVet',
        builder: (context, state) {
          final vetId = state.pathParameters['id']!;
          return VetFormScreen(vetId: vetId);
        },
      ),
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/shared/:code',
        name: 'sharedPet',
        builder: (context, state) {
          final code = state.pathParameters['code']!;
          return SharedPetScreen(shareCode: code);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
