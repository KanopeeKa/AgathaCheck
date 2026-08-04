import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
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
    this.screenTitle,
    this.contextualActions = const [],
    this.backPath,
  });

  final AppExperience experience;
  final String currentLocation;
  final Widget child;

  /// Centered logo + title in the app bar (omit on screens that set their own).
  final String? screenTitle;

  /// Icons/menus to the right of the title, before `|` and the notification bell.
  final List<Widget> contextualActions;

  /// When [Navigator.canPop] is false, navigate here instead of the section root.
  final String? backPath;

  bool _isRoot() => DrawerMenuConfig.sectionRootPaths.contains(currentLocation);

  String _sectionRoot() => switch (experience) {
    AppExperience.guardian => '/g/home',
    AppExperience.organization => '/o/orgs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(organisationMembershipVisibilitySyncProvider);
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
                    tooltip: l.sectionDrawerTooltip,
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                )
              : IconButton(
                  key: const Key('experience_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => _onBack(context),
                ),
          centerTitle: true,
          title: screenTitle == null
              ? const SizedBox.shrink()
              : AppLogoTitle(title: screenTitle!, experience: experience),
          actions: [
            if (contextualActions.isNotEmpty) ...contextualActions,
            if (contextualActions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '|',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Builder(
              builder: (ctx) {
                final bellTooltip = combinedUnread > 0
                    ? l.drawerItemUnreadSemantics(
                        l.notificationsBellTooltip,
                        combinedUnread,
                      )
                    : l.notificationsBellTooltip;
                // Omit Badge when count is zero — hidden Badge labels leave stale
                // aria-owns targets on Flutter web (axe aria-valid-attr-value).
                final bellIcon = combinedUnread > 0
                    ? Badge(
                        isLabelVisible: true,
                        label: Text('$combinedUnread'),
                        child: const Icon(Icons.notifications_outlined),
                      )
                    : const Icon(Icons.notifications_outlined);
                return Semantics(
                  button: true,
                  label: bellTooltip,
                  child: ExcludeSemantics(
                    child: IconButton(
                      key: const Key('experience_notification_bell'),
                      icon: bellIcon,
                      onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                    ),
                  ),
                );
              },
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
      context.go(backPath ?? _sectionRoot());
    }
  }
}
