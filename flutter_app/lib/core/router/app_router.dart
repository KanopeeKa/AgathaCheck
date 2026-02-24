import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import '../../features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_list_screen.dart';

/// Defines all application routes using [GoRouter].
///
/// Routes:
/// - `/` : Pet list (home) screen
/// - `/add` : Add new pet form
/// - `/edit/:id` : Edit existing pet form
/// - `/health` : Health tracking dashboard
/// - `/health/add` : Add new health entry
/// - `/health/edit/:id` : Edit existing health entry
class AppRouter {
  AppRouter._();

  /// The configured [GoRouter] instance for the application.
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const PetListScreen(),
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
        path: '/health',
        name: 'healthDashboard',
        builder: (context, state) => const HealthDashboardScreen(),
      ),
      GoRoute(
        path: '/health/add',
        name: 'addHealthEntry',
        builder: (context, state) => const HealthEntryFormScreen(),
      ),
      GoRoute(
        path: '/health/edit/:id',
        name: 'editHealthEntry',
        builder: (context, state) {
          final entryId = state.pathParameters['id']!;
          return HealthEntryFormScreen(entryId: entryId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
