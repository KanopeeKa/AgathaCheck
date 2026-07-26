import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../utils/experience_theme.dart';
import 'experience_section_drawer.dart';

/// Shell scaffold shared by guardian and organisation experience screens.
///
/// Navigation reversal (phase-1-navigation.md):
/// - Hamburger on section roots (`/g/home`, `/o/orgs`, `/account`).
/// - Back arrow on all other screens (Navigator.canPop → pop; else → section root).
/// - Persistent bell with combined unread badge opens notification panel (endDrawer).
/// - No Home button.
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

  bool _isRoot() => DrawerMenuConfig.sectionRootPaths.contains(currentLocation);

  String _sectionRoot() => switch (experience) {
    AppExperience.guardian => '/g/home',
    AppExperience.organization => '/o/orgs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final combinedUnread = ref.watch(combinedUnreadNotificationCountProvider);
    final shellTheme = themeForAppExperience(theme, experience);
    final isRoot = _isRoot();

    return Theme(
      data: shellTheme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: isRoot
              ? Builder(
                  builder: (ctx) => IconButton(
                    key: const Key('experience_settings_menu'),
                    icon: const Icon(Icons.menu),
                    tooltip: l.settings,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : IconButton(
                  key: const Key('experience_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => _onBack(context),
                ),
          title: const SizedBox.shrink(),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                key: const Key('experience_notification_bell'),
                icon: Badge(
                  isLabelVisible: combinedUnread > 0,
                  label: Text('$combinedUnread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: l.notificationsBellTooltip,
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ],
        ),
        drawer: const ExperienceSectionDrawer(),
        endDrawer: const NotificationPanel(),
        body: child,
      ),
    );
  }

  void _onBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      context.go(_sectionRoot());
    }
  }
}
