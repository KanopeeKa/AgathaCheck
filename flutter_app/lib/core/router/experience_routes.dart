import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/experience/domain/entities/app_experience.dart';
import '../../features/experience/presentation/screens/experience_chooser_screen.dart';
import '../../features/experience/presentation/screens/experience_home_screens.dart';
import '../../features/experience/presentation/screens/experience_resolve_screen.dart';
import '../../features/experience/presentation/screens/experience_settings_screen.dart';
import '../../features/experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../features/health_tracking/domain/health_events_scope.dart';
import '../../features/health_tracking/presentation/screens/health_dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

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
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        GoRoute(
          path: '/g/home',
          name: 'guardianHome',
          builder: (context, state) => const GuardianHomeScreen(),
        ),
        GoRoute(
          path: '/g/events',
          name: 'guardianEvents',
          builder: (context, state) => const _GuardianEventsScreen(),
        ),
        GoRoute(
          path: '/g/settings',
          name: 'guardianSettings',
          builder: (context, state) => const ExperienceSettingsScreen(
            experience: AppExperience.guardian,
          ),
        ),
        GoRoute(
          path: '/g/invite',
          name: 'guardianInvite',
          builder: (context, state) =>
              const ExperienceInviteScreen(experience: AppExperience.guardian),
        ),
        GoRoute(
          path: '/g/notifications',
          name: 'guardianNotifications',
          builder: (context, state) => const _GuardianNotificationsScreen(),
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
          builder: (context, state) => const _OrgEventsScreen(),
        ),
        GoRoute(
          path: '/o/settings',
          name: 'orgSettings',
          builder: (context, state) => const ExperienceSettingsScreen(
            experience: AppExperience.organization,
          ),
        ),
        GoRoute(
          path: '/o/invite',
          name: 'orgInvite',
          builder: (context, state) => const ExperienceInviteScreen(
            experience: AppExperience.organization,
          ),
        ),
        GoRoute(
          path: '/o/notifications',
          name: 'orgNotifications',
          builder: (context, state) => const _OrgNotificationsScreen(),
        ),
      ],
    ),
  ];
}

class _GuardianEventsScreen extends StatelessWidget {
  const _GuardianEventsScreen();

  @override
  Widget build(BuildContext context) {
    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const HealthDashboardScreen(
        embeddedInShell: true,
        scope: HealthEventsScope.guardian,
        backPath: '/g/home',
      ),
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

class _GuardianNotificationsScreen extends StatelessWidget {
  const _GuardianNotificationsScreen();

  @override
  Widget build(BuildContext context) {
    return ExperienceShellScaffold(
      experience: AppExperience.guardian,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const NotificationsScreen(backPath: '/g/home'),
    );
  }
}

class _OrgNotificationsScreen extends StatelessWidget {
  const _OrgNotificationsScreen();

  @override
  Widget build(BuildContext context) {
    return ExperienceShellScaffold(
      experience: AppExperience.organization,
      currentLocation: GoRouterState.of(context).uri.path,
      child: const NotificationsScreen(backPath: '/o/home'),
    );
  }
}
