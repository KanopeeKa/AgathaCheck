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
import '../../features/health_tracking/presentation/screens/other_event_form_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_form_screen.dart';
import '../../features/pet_profile/presentation/widgets/pet_edit_permission_guard.dart';
import '../../features/organization/presentation/screens/archived_pets_screen.dart';
import '../../features/sharing/presentation/screens/shared_pet_screen.dart';
import '../../features/about/presentation/screens/about_screen.dart';
import '../../features/about/presentation/screens/legal_document_screen.dart';
import '../../features/about/presentation/screens/legal_documents_screen.dart';
import '../../features/about/domain/legal_document_id.dart';
import '../../features/help/presentation/screens/help_screen.dart';
import '../../features/subscription/presentation/screens/paywall_screen.dart';
import '../widgets/consent_banner.dart';
import '../providers/analytics_providers.dart';
import 'experience_routes.dart';
import 'organization_routes.dart';
import 'vet_routes.dart';

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
  final analyticsObserver = ref.watch(analyticsRouteObserverProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,
    observers: [analyticsObserver],
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
        if (LegalDocumentId.publicRoutes.contains(path)) return null;
        if (path.startsWith('/legal/')) return null;
        return '/landing';
      }

      if (isLoggedIn && path == '/landing') {
        return '/app/resolve';
      }

      if (isLoggedIn && path == '/') {
        return '/app/resolve';
      }

      return null;
    },
    routes: [
      ...buildExperienceRoutes(),
      ...buildVetExperienceRoutes(),
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
        name: 'legacyHome',
        redirect: (context, state) => '/app/resolve',
      ),
      GoRoute(
        path: '/my-details',
        name: 'myDetails',
        builder: (context, state) => const MyDetailsScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/legal',
        name: 'legal',
        builder: (context, state) => const LegalDocumentsScreen(),
      ),
      GoRoute(
        path: '/legal/:document',
        name: 'legalDocument',
        builder: (context, state) {
          final segment = state.pathParameters['document']!;
          final documentId = LegalDocumentId.fromRouteSegment(segment);
          if (documentId == null) {
            return const LegalDocumentsScreen();
          }
          return LegalDocumentScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacyPolicy',
        redirect: (context, state) => '/legal/privacy-notice',
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'termsOfService',
        redirect: (context, state) => '/legal/terms-of-use',
      ),
      GoRoute(
        path: '/add',
        name: 'addPet',
        builder: (context, state) {
          final orgIdStr = state.uri.queryParameters['orgId'];
          return PetFormScreen(initialOrgId: orgIdStr);
        },
      ),
      GoRoute(
        path: '/edit/:id',
        name: 'editPet',
        builder: (context, state) {
          final petId = state.pathParameters['id']!;
          return PetEditPermissionGuard(petId: petId);
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
              ? HealthEntryType.values
                    .where((t) => t.name == typeParam)
                    .firstOrNull
              : null;
          return HealthEntryFormScreen(
            petId: petId,
            initialType: initialType,
            allowedTypes: kHealthEventTypes.toList(),
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/health/edit/:id',
        name: 'editPetHealthEntry',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final entryId = state.pathParameters['id']!;
          return HealthEntryFormScreen(
            entryId: entryId,
            petId: petId,
            allowedTypes: kHealthEventTypes.toList(),
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/other/add',
        name: 'addPetOtherEvent',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final typeParam = state.uri.queryParameters['type'];
          final initialType = typeParam != null
              ? HealthEntryType.values
                    .where((t) => t.name == typeParam)
                    .firstOrNull
              : null;
          return OtherEventFormScreen(petId: petId, initialType: initialType);
        },
      ),
      GoRoute(
        path: '/pet/:petId/other/edit/:id',
        name: 'editPetOtherEvent',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final entryId = state.pathParameters['id']!;
          return OtherEventFormScreen(entryId: entryId, petId: petId);
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
              ? HealthEntryType.values
                    .where((t) => t.name == typeParam)
                    .firstOrNull
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
        redirect: (context, state) => redirectLegacyVetPath(state) ?? '/g/vets',
      ),
      GoRoute(
        path: '/vets/add',
        redirect: (context, state) =>
            redirectLegacyVetPath(state) ?? '/g/vets/add',
      ),
      GoRoute(
        path: '/vets/edit/:id',
        redirect: (context, state) =>
            redirectLegacyVetPath(state) ??
            '/g/vets/edit/${state.pathParameters['id']}',
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
      ...buildOrgManagementRoutes(),
      GoRoute(
        path: '/organizations',
        redirect: (context, state) =>
            redirectLegacyOrganizationPath(state) ?? '/o/orgs',
      ),
      GoRoute(
        path: '/organizations/:tail(.*)',
        redirect: (context, state) =>
            redirectLegacyOrganizationPath(state) ?? '/o/orgs',
      ),
      GoRoute(
        path: '/archived-pets',
        name: 'userArchivedPets',
        builder: (context, state) => const ArchivedPetsScreen(),
      ),
      GoRoute(
        path: '/consent-settings',
        name: 'consentSettings',
        builder: (context, state) => const ConsentSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
