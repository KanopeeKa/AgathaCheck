import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../domain/entities/app_experience.dart';
import '../providers/experience_providers.dart';
import '../utils/experience_theme.dart';
import 'guardian_experience_drawer.dart';
import 'org_experience_drawer.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibility = ref.watch(experienceEligibilityProvider).valueOrNull;
    final guardianUnread = ref.watch(guardianUnreadNotificationCountProvider);
    final orgUnread = ref.watch(orgUnreadNotificationCountProvider);
    final isFosterPortal = ref.watch(isFosterPortalUserProvider);
    final isOrg = experience == AppExperience.organization;
    final shellTheme = themeForAppExperience(theme, experience);
    final menuUnread = isOrg ? orgUnread : guardianUnread;

    return Theme(
      data: shellTheme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  key: const Key('experience_settings_menu'),
                  icon: Badge(
                    isLabelVisible: menuUnread > 0,
                    label: Text('$menuUnread'),
                    child: const Icon(Icons.menu),
                  ),
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
                        ? shellTheme.colorScheme.primary
                        : shellTheme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: isOrg
            ? OrgExperienceDrawer(
                showGuardianView: eligibility?.canUseGuardian ?? true,
                isFosterPortal: isFosterPortal,
              )
            : const GuardianExperienceDrawer(),
        body: child,
      ),
    );
  }
}
