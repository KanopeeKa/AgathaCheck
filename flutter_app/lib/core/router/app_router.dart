import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/my_details_screen.dart';
import '../../features/health_tracking/domain/entities/health_entry.dart';
import '../../features/health_tracking/presentation/screens/health_entry_form_screen.dart';
import '../../features/health_tracking/presentation/screens/pet_event_view_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/pending_actions_screen.dart';
import '../../features/fostering_session/presentation/screens/foster_fostering_session_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_detail_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_health_issues_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_manage_events_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_form_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_timeline_screen.dart';
import '../../features/pet_profile/presentation/screens/pet_weight_tracking_screen.dart';
import '../../features/pet_profile/presentation/widgets/pet_edit_permission_guard.dart';
import '../../features/experience/presentation/screens/pet_care/pet_care_desk_preview_screen.dart';
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

bool get _designReviewEnabled {
  final host = Uri.base.host.toLowerCase();
  return host == '127.0.0.1' ||
      host == 'localhost' ||
      host.endsWith('.replit.dev');
}

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
  final initialLocation =
      _designReviewEnabled && Uri.base.path == '/preview/guardian-desk'
      ? '/preview/guardian-desk'
      : '/';

  return GoRouter(
    initialLocation: initialLocation,
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
        if (_designReviewEnabled && path == '/preview/guardian-desk') {
          return null;
        }
        if (path == '/forgot-password') return null;
        if (path.startsWith('/shared/')) return null;
        if (isPublicOrganizationProfilePath(path)) return null;
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
      if (_designReviewEnabled)
        GoRoute(
          path: '/preview/guardian-desk',
          name: 'guardianDeskPreview',
          builder: (context, state) => const PetCareDeskPreviewScreen(),
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
        path: '/pet/:petId/fostering-session',
        name: 'fosterFosteringSessionDetail',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final placementId = state.uri.queryParameters['placementId'] ?? '';
          return FosterFosteringSessionDetailScreen(
            petId: petId,
            placementId: placementId,
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/events',
        name: 'petManageEvents',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetManageEventsScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pet/:petId/events/:entryId/edit',
        name: 'editPetEvent',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final entryId = state.pathParameters['entryId']!;
          return HealthEntryFormScreen(
            entryId: entryId,
            petId: petId,
            allowedTypes: kAllPetEventTypes,
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/events/:entryId',
        name: 'petEventView',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          final entryId = state.pathParameters['entryId']!;
          return PetEventViewScreen(petId: petId, entryId: entryId);
        },
      ),
      GoRoute(
        path: '/pet/:petId/timeline',
        name: 'petTimeline',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetTimelineScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pet/:petId/weight',
        name: 'petWeightTracking',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetWeightTrackingScreen(petId: petId);
        },
      ),
      GoRoute(
        path: '/pet/:petId/health-issues',
        name: 'petHealthIssues',
        builder: (context, state) {
          final petId = state.pathParameters['petId']!;
          return PetHealthIssuesScreen(petId: petId);
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
            allowedTypes: kAllPetEventTypes,
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/health/edit/:id',
        name: 'editPetHealthEntry',
        redirect: (context, state) => redirectLegacyPetEventEditPath(state),
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
              : HealthEntryType.other;
          return HealthEntryFormScreen(
            petId: petId,
            initialType: initialType,
            allowedTypes: kOtherEventTypes.toList(),
          );
        },
      ),
      GoRoute(
        path: '/pet/:petId/other/edit/:id',
        name: 'editPetOtherEvent',
        redirect: (context, state) => redirectLegacyPetEventEditPath(state),
      ),
      GoRoute(
        path: '/health',
        name: 'healthDashboard',
        redirect: (context, state) => '/pc/events',
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
        path: '/pending-actions',
        name: 'pendingActions',
        builder: (context, state) {
          final focus = state.uri.queryParameters['focus'];
          return PendingActionsScreen(focus: focus);
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
        redirect: (context, state) =>
            redirectLegacyVetPath(state) ?? '/pc/vets',
      ),
      GoRoute(
        path: '/vets/add',
        redirect: (context, state) =>
            redirectLegacyVetPath(state) ?? '/pc/vets/add',
      ),
      GoRoute(
        path: '/vets/edit/:id',
        redirect: (context, state) =>
            redirectLegacyVetPath(state) ??
            '/pc/vets/edit/${state.pathParameters['id']}',
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
