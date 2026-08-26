import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../l10n/app_localizations.dart';
import '../../features/experience/presentation/screens/account_screen.dart';
import '../../features/organization/presentation/screens/account_org_settings_screen.dart';
import '../../features/experience/presentation/screens/experience_chooser_screen.dart';
import '../../features/experience/presentation/screens/experience_home_screens.dart';
import '../../features/experience/presentation/screens/experience_resolve_screen.dart';
import '../../features/experience/presentation/screens/experience_settings_screen.dart';
import '../../features/experience/presentation/screens/guardian_onboarding_screen.dart';
import '../../features/experience/presentation/screens/org_onboarding_screen.dart';
import '../../features/experience/presentation/widgets/foster_portal_route_guard.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/experience/presentation/screens/guardian/guardian_all_pets_screen.dart';
import '../../features/experience/presentation/screens/guardian/add_event_type_picker_sheet.dart';
import '../../features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import '../../features/experience/presentation/screens/guardian/guardian_fostering_screen.dart';
import '../../features/health_tracking/domain/health_events_scope.dart';
import '../../features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import '../../features/pet_profile/domain/entities/pet.dart';
import '../../features/pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../features/pet_profile/presentation/providers/pet_providers.dart';

List<RouteBase> buildExperienceRoutes() {
  return [
    GoRoute(
      path: '/app/resolve',
      name: 'experienceResolve',
      builder: (context, state) => const ExperienceResolveScreen(),
    ),
    GoRoute(
      path: '/app/choose',
      name: 'experienceChoose',
      builder: (context, state) => const ExperienceChooserScreen(),
    ),
    GoRoute(
      path: '/g/onboarding',
      name: 'guardianOnboarding',
      builder: (context, state) => const GuardianOnboardingScreen(),
    ),
    GoRoute(
      path: '/o/onboarding',
      name: 'orgOnboarding',
      builder: (context, state) => const OrgOnboardingScreen(),
    ),
    // Account section root (navigation reversal, phase-1-navigation.md)
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
      routes: [
        GoRoute(
          path: 'orgs/:orgId',
          name: 'accountOrgSettings',
          builder: (context, state) {
            final highlightLeave =
                state.uri.queryParameters['highlight'] == 'leave';
            return AccountOrgSettingsScreen(
              orgId: state.pathParameters['orgId']!,
              highlightLeave: highlightLeave,
            );
          },
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/g/home',
          name: 'guardianHome',
          builder: (context, state) => const GuardianHomeScreen(),
        ),
        GoRoute(
          path: '/g/pets',
          name: 'guardianAllPets',
          builder: (context, state) => const GuardianAllPetsScreen(),
        ),
        GoRoute(
          path: '/g/events',
          name: 'guardianEvents',
          builder: (context, state) => const _GuardianEventsScreen(),
        ),
        GoRoute(
          path: '/g/fostering',
          name: 'guardianFostering',
          builder: (context, state) => const GuardianFosteringScreen(),
        ),
        GoRoute(
          path: '/g/invite',
          name: 'guardianInvite',
          builder: (context, state) =>
              const ExperienceInviteScreen(experience: AppExperience.guardian),
        ),
        // Deprecated: /g/settings → /account
        GoRoute(
          path: '/g/settings',
          name: 'guardianSettings',
          redirect: (context, state) => '/account',
        ),
        // Deprecated: /g/notifications → bell-only (slide-over panel)
        GoRoute(
          path: '/g/notifications',
          name: 'guardianNotifications',
          redirect: (context, state) => '/g/home',
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/o/home',
          name: 'orgHome',
          builder: (context, state) => const OrgHomeScreen(),
        ),
        GoRoute(
          path: '/o/events',
          name: 'orgEvents',
          builder: (context, state) => const FosterPortalRouteGuard(
            fallbackPath: '/o/home',
            child: _OrgEventsScreen(),
          ),
        ),
        GoRoute(
          path: '/o/invite',
          name: 'orgInvite',
          builder: (context, state) => const FosterPortalRouteGuard(
            fallbackPath: '/o/home',
            child: ExperienceInviteScreen(
              experience: AppExperience.organization,
            ),
          ),
        ),
        // Deprecated: /o/settings → /account
        GoRoute(
          path: '/o/settings',
          name: 'orgSettings',
          redirect: (context, state) => '/account',
        ),
        // Deprecated: /o/notifications → bell-only (slide-over panel)
        GoRoute(
          path: '/o/notifications',
          name: 'orgNotifications',
          redirect: (context, state) => '/o/orgs',
        ),
      ],
    ),
  ];
}

class _GuardianEventsScreen extends ConsumerWidget {
  const _GuardianEventsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);
    final allPets = petsAsync.valueOrNull ?? const <Pet>[];
    final shellPets = PetListController().guardianShellPets(allPets);
    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.eventsNavLabel,
      backPath: '/g/home',
      contextualActions: [
        IconButton(
          key: const Key('global_events_add_app_bar'),
          tooltip: l.addAnEvent,
          icon: const Icon(Icons.add),
          onPressed: petsAsync.hasValue
              ? () => showAddEventTypePickerSheet(context, pets: shellPets)
              : null,
        ),
      ],
      child: const GuardianDueEventsScreen(),
    );
  }
}

class _OrgEventsScreen extends StatelessWidget {
  const _OrgEventsScreen();

  @override
  Widget build(BuildContext context) {
    return ExperienceShellScaffold(
      experience: AppExperience.organization,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const HealthDashboardScreen(
        embeddedInShell: true,
        scope: HealthEventsScope.organization,
        backPath: '/o/home',
      ),
    );
  }
}
