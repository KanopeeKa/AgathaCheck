import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/shell_notification_bell.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/widgets/org_shell_app_bar_title.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../providers/experience_providers.dart';
import '../utils/experience_theme.dart';
import 'experience_section_drawer.dart';
import 'experience_workspace_toggle.dart';
import '../config/guardian_primary_destinations.dart';
import 'guardian_bottom_navigation.dart';
import 'guardian_navigation_rail.dart';
import 'guardian_navigation_sidebar.dart';
import '../../../organization/presentation/utils/org_screen_theme.dart';

/// Shell scaffold shared by guardian and organisation experience screens.
///
/// Navigation reversal (phase-1-navigation.md):
/// - Workspace toggle on section roots (`/g/home`, `/o/orgs`, `/account`).
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
    this.orgNavVariant,
    this.organization,
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

  /// Organisation nav title variant (D-v3-NAV-1). When set with [screenTitle],
  /// replaces [AppLogoTitle] for organisation experience screens.
  final OrgNavTitleVariant? orgNavVariant;

  /// Optional org for thumbnail titles in the org shell.
  final Organization? organization;

  bool _isRoot() => DrawerMenuConfig.sectionRootPaths.contains(currentLocation);

  String _sectionRoot() => switch (experience) {
    AppExperience.guardian => '/g/home',
    AppExperience.organization => '/o/orgs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellTheme = themeForAppExperience(theme, experience);
    final isRoot = _isRoot();
    if (isRoot) {
      ref.watch(organisationMembershipVisibilitySyncProvider);
    }
    final isOrg = experience == AppExperience.organization;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isGuardianExperience = experience == AppExperience.guardian;
    final usesGuardianPrimaryNavigation =
        isGuardianExperience &&
        GuardianPrimaryDestinations.isCompact(viewportWidth);
    final usesGuardianNavigationSidebar =
        isGuardianExperience &&
        GuardianPrimaryDestinations.isExpanded(viewportWidth);
    final usesGuardianNavigationRail =
        isGuardianExperience &&
        GuardianPrimaryDestinations.isMedium(viewportWidth);
    final usesGuardianLeadingNav =
        usesGuardianNavigationRail || usesGuardianNavigationSidebar;
    final hideGuardianDrawer = usesGuardianLeadingNav;
    final appBarColor = usesGuardianPrimaryNavigation
        ? AppColorTokens.guardianPrimary
        : AppColorTokens.background;
    final appBarForeground = usesGuardianPrimaryNavigation
        ? AppColorTokens.inverse
        : null;
    final useOrgTitle = isOrg && screenTitle != null && orgNavVariant != null;
    final showWorkspaceToggleInAppBar = isRoot && !usesGuardianLeadingNav;
    final showShelterWorkspace =
        isRoot &&
        (currentLocation.startsWith('/o/') ||
            ref.watch(showOrganisationSectionProvider));
    final workspaceToggleWidth = showShelterWorkspace ? 184.0 : 132.0;
    final hideTitleForAccessibleCompactHeader =
        isRoot &&
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(14) > 18;
    final usesGuardianDesktopContentHeader =
        isGuardianExperience && usesGuardianLeadingNav;

    return Theme(
      data: shellTheme,
      child: Scaffold(
        backgroundColor: isOrg
            ? orgListScaffoldBackground(context)
            : experience == AppExperience.guardian
            ? AppColorTokens.background
            : null,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          leadingWidth: showWorkspaceToggleInAppBar
              ? workspaceToggleWidth
              : null,
          backgroundColor: appBarColor,
          foregroundColor: appBarForeground,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: showWorkspaceToggleInAppBar
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ExperienceWorkspaceToggle(
                    currentLocation: currentLocation,
                    onDarkBackground: usesGuardianPrimaryNavigation,
                    showShelter: showShelterWorkspace,
                  ),
                )
              : !isRoot
              ? IconButton(
                  key: const Key('experience_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => _onBack(context),
                )
              : null,
          centerTitle: !usesGuardianDesktopContentHeader,
          title: screenTitle == null || hideTitleForAccessibleCompactHeader
              ? const SizedBox.shrink()
              : useOrgTitle
              ? OrgShellAppBarTitle(
                  title: screenTitle!,
                  variant: orgNavVariant!,
                  organization: organization,
                )
              : usesGuardianDesktopContentHeader
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    screenTitle!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColorTokens.heading,
                    ),
                  ),
                )
              : AppLogoTitle(
                  title: screenTitle!,
                  experience: experience,
                  useShellLogo: usesGuardianPrimaryNavigation,
                ),
          actions: [
            if (contextualActions.isNotEmpty) ...contextualActions,
            if (contextualActions.isNotEmpty)
              VerticalDivider(
                width: 16,
                indent: 18,
                endIndent: 18,
                color: usesGuardianPrimaryNavigation
                    ? AppColorTokens.guardianLight
                    : theme.colorScheme.outlineVariant,
              ),
            Builder(builder: (ctx) => const ShellNotificationBell()),
          ],
        ),
        drawer: hideGuardianDrawer ? null : const ExperienceSectionDrawer(),
        endDrawer: const NotificationPanel(),
        body: usesGuardianLeadingNav
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usesGuardianNavigationSidebar)
                    GuardianNavigationSidebar(currentLocation: currentLocation)
                  else
                    GuardianNavigationRail(currentLocation: currentLocation),
                  Expanded(child: child),
                ],
              )
            : child,
        bottomNavigationBar: usesGuardianPrimaryNavigation
            ? GuardianBottomNavigation(currentLocation: currentLocation)
            : null,
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
