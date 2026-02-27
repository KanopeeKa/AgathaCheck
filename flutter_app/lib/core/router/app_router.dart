import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/my_details_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import '../../features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_list_screen.dart';
import '../../features/sharing/presentation/screens/shared_pet_screen.dart';
import '../../features/vet/presentation/screens/vet_form_screen.dart';
import '../../features/vet/presentation/screens/vet_list_screen.dart';

/// Configures the application's route hierarchy using [GoRouter].
///
/// Defines all navigable routes including pet profiles, health tracking,
/// veterinarian management, authentication, and shared pet views.
class AppRouter {
  /// Private constructor to prevent instantiation.
  AppRouter._();

  /// The [GoRouter] instance that manages navigation for the entire app.
  ///
  /// Routes include:
  /// - `/` — Home screen with the pet list
  /// - `/pet/:petId` — Pet detail screen
  /// - `/add`, `/edit/:id` — Pet form screens
  /// - `/health`, `/health/add`, `/health/edit/:id` — Health tracking
  /// - `/vets`, `/vets/add`, `/vets/edit/:id` — Veterinarian management
  /// - `/shared/:code` — Shared pet view (public, no auth required)
  /// - `/login`, `/signup`, `/my-details` — Authentication screens
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const PetListScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
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
          return HealthEntryFormScreen(petId: petId);
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
}
