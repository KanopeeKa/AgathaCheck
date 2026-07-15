import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../providers/experience_providers.dart';

/// Top navigation + settings drawer shared by guardian and organisation shells.
class ExperienceShellScaffold extends ConsumerWidget {
  const ExperienceShellScaffold({
    super.key,
    required this.experience,
    required this.currentLocation,
    required this.child,
  });

  final AppExperience experience;
  final String currentLocation;
  final Widget child;

  bool get _isHome =>
      currentLocation == '/g/home' ||
      currentLocation.startsWith('/o/home') ||
      (experience == AppExperience.organization &&
          RegExp(r'^/o/[^/]+$').hasMatch(currentLocation));

  bool get _isEvents =>
      currentLocation == '/g/events' || currentLocation == '/o/events';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibility = ref.watch(experienceEligibilityProvider).valueOrNull;
    final unread = ref.watch(unreadNotificationCountProvider);
    final isFosterPortal = ref.watch(isFosterPortalUserProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (ctx) => IconButton(
                key: const Key('experience_settings_menu'),
                icon: const Icon(Icons.menu),
                tooltip: l.settings,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              key: const Key('experience_nav_home'),
              onPressed: _isHome
                  ? null
                  : () => context.go(experience.homePath()),
              child: Text(
                l.home,
                style: TextStyle(
                  fontWeight: _isHome ? FontWeight.bold : FontWeight.normal,
                  color: _isHome
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              key: const Key('experience_nav_events'),
              onPressed: _isEvents
                  ? null
                  : () => context.go(experience.eventsPath),
              icon: Icon(
                Icons.event,
                color: _isEvents
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              label: Text(
                l.eventsNavLabel,
                style: TextStyle(
                  fontWeight: _isEvents ? FontWeight.bold : FontWeight.normal,
                  color: _isEvents
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: _ExperienceDrawer(
        experience: experience,
        unreadCount: unread,
        showOrgView: eligibility?.canUseOrganization ?? false,
        showGuardianView: eligibility?.canUseGuardian ?? true,
        isFosterPortal:
            experience == AppExperience.organization && isFosterPortal,
      ),
      body: child,
    );
  }
}

class _ExperienceDrawer extends ConsumerWidget {
  const _ExperienceDrawer({
    required this.experience,
    required this.unreadCount,
    required this.showOrgView,
    required this.showGuardianView,
    required this.isFosterPortal,
  });

  final AppExperience experience;
  final int unreadCount;
  final bool showOrgView;
  final bool showGuardianView;
  final bool isFosterPortal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                auth.user?.firstName?.isNotEmpty == true
                    ? auth.user!.firstName!
                    : (auth.user?.email ?? ''),
              ),
              accountEmail: Text(auth.user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                child: Text(
                  (auth.user?.firstName?.isNotEmpty == true
                          ? auth.user!.firstName![0]
                          : auth.user?.email[0] ?? 'U')
                      .toUpperCase(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l.settings),
              onTap: () {
                Navigator.pop(context);
                context.push(experience.settingsPath);
              },
            ),
            ListTile(
              leading: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: const Icon(Icons.notifications_outlined),
              ),
              title: Text(l.notifications),
              onTap: () {
                Navigator.pop(context);
                final prefix = experience == AppExperience.guardian
                    ? '/g'
                    : '/o';
                context.push('$prefix/notifications');
              },
            ),
            if (!isFosterPortal)
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(l.upcomingEvents),
                onTap: () {
                  Navigator.pop(context);
                  context.go(experience.eventsPath);
                },
              ),
            if (!isFosterPortal)
              ListTile(
                key: const Key('drawer_invite'),
                leading: const Icon(Icons.person_add_outlined),
                title: Text(l.invite),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    experience == AppExperience.guardian
                        ? '/g/invite'
                        : '/o/invite',
                  );
                },
              ),
            const Divider(),
            if (experience == AppExperience.guardian && showOrgView)
              ListTile(
                key: const Key('drawer_org_view'),
                leading: const Icon(Icons.business_outlined),
                title: Text(l.experienceOrgView),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(activeExperienceProvider.notifier).state =
                      AppExperience.organization;
                  context.go(AppExperience.organization.homePath());
                },
              ),
            if (experience == AppExperience.organization && showGuardianView)
              ListTile(
                key: const Key('drawer_guardian_view'),
                leading: const Icon(Icons.pets_outlined),
                title: Text(l.experienceGuardianView),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(activeExperienceProvider.notifier).state =
                      AppExperience.guardian;
                  context.go(AppExperience.guardian.homePath());
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.aboutUs),
              onTap: () {
                Navigator.pop(context);
                context.push('/about');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(l.contact),
              onTap: () {
                Navigator.pop(context);
                context.push('/help');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l.logOut),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
