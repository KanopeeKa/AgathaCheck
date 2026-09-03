import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/shell_notification_bell.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/widgets/org_shell_app_bar_title.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
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
/// - Workspace toggle on section roots (`/pc/home`, `/o/orgs`, `/account`).
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
    this.forceBackPath = false,
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

  /// When true, [backPath] is used even when [Navigator.canPop] is true.
  final bool forceBackPath;

  /// Organisation nav title variant (D-v3-NAV-1). When set with [screenTitle],
  /// replaces [AppLogoTitle] for organisation experience screens.
  final OrgNavTitleVariant? orgNavVariant;

  /// Optional org for thumbnail titles in the org shell.
  final Organization? organization;

  static const _toolbarHeight = 64.0;

  bool _isRoot() => DrawerMenuConfig.sectionRootPaths.contains(currentLocation);

  String _sectionRoot() => switch (experience) {
    AppExperience.petCare => '/pc/home',
    AppExperience.organization => '/o/orgs',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellTheme = themeForAppExperience(theme, experience);
    final isRoot = _isRoot();
    final isOrg = experience == AppExperience.organization;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isGuardianExperience = experience == AppExperience.petCare;
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
        ? AppColorTokens.petCarePrimary
        : AppColorTokens.background;
    final appBarForeground = usesGuardianPrimaryNavigation
        ? AppColorTokens.inverse
        : null;
    final useOrgTitle = isOrg && screenTitle != null && orgNavVariant != null;
    const showShelterWorkspace = true;
    const workspaceToggleWidth = 184.0;
    final leadingWidth = usesGuardianLeadingNav
        ? (isRoot ? null : 56.0)
        : (isRoot ? workspaceToggleWidth : workspaceToggleWidth + 48);
    final hideTitleForAccessibleCompactHeader =
        isRoot &&
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(14) > 18;
    final suppressGuardianSectionRootAppBarTitle =
        isGuardianExperience && usesGuardianLeadingNav && isRoot;
    final usesGuardianDesktopContentHeader =
        isGuardianExperience &&
        usesGuardianLeadingNav &&
        !suppressGuardianSectionRootAppBarTitle;
    final showTitle =
        screenTitle != null &&
        !hideTitleForAccessibleCompactHeader &&
        !suppressGuardianSectionRootAppBarTitle;
    final titleWidget = !showTitle
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
          );
    final trailingActions = _buildTrailingActions(
      theme: theme,
      usesGuardianPrimaryNavigation: usesGuardianPrimaryNavigation,
    );
    final leadingWidget = usesGuardianLeadingNav
        ? (!isRoot
              ? IconButton(
                  key: const Key('experience_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => _onBack(context),
                )
              : null)
        : _buildCompactShellLeading(
            context: context,
            l: l,
            isRoot: isRoot,
            usesGuardianPrimaryNavigation: usesGuardianPrimaryNavigation,
            currentLocation: currentLocation,
            showShelterWorkspace: showShelterWorkspace,
          );

    return Theme(
      data: shellTheme,
      child: Scaffold(
        backgroundColor: isOrg
            ? orgListScaffoldBackground(context)
            : experience == AppExperience.petCare
            ? AppColorTokens.background
            : null,
        appBar: usesGuardianLeadingNav
            ? null
            : AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: _toolbarHeight,
                leadingWidth: leadingWidth,
                backgroundColor: appBarColor,
                foregroundColor: appBarForeground,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                leading: leadingWidget,
                centerTitle: !usesGuardianDesktopContentHeader,
                title: titleWidget,
                actions: trailingActions,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ContentChromeBar(
                          backgroundColor: appBarColor,
                          foregroundColor: appBarForeground,
                          leading: leadingWidget,
                          leadingWidth: leadingWidth ?? 56,
                          title: titleWidget,
                          centerTitle: !usesGuardianDesktopContentHeader,
                          actions: trailingActions,
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ],
              )
            : child,
        bottomNavigationBar: usesGuardianPrimaryNavigation
            ? GuardianBottomNavigation(currentLocation: currentLocation)
            : null,
      ),
    );
  }

  List<Widget> _buildTrailingActions({
    required ThemeData theme,
    required bool usesGuardianPrimaryNavigation,
  }) {
    return [
      if (contextualActions.isNotEmpty) ...contextualActions,
      if (contextualActions.isNotEmpty)
        VerticalDivider(
          width: 16,
          indent: 18,
          endIndent: 18,
          color: usesGuardianPrimaryNavigation
              ? AppColorTokens.petCareLight
              : theme.colorScheme.outlineVariant,
        ),
      Builder(builder: (ctx) => const ShellNotificationBell()),
    ];
  }

  void _onBack(BuildContext context) {
    final returnTo = shellReturnToFromState(GoRouterState.of(context));
    handleShellBack(
      context,
      backPath: backPath,
      returnTo: returnTo,
      defaultPath: backPath ?? _sectionRoot(),
      forceBackPath: forceBackPath,
    );
  }

  Widget _buildCompactShellLeading({
    required BuildContext context,
    required AppLocalizations l,
    required bool isRoot,
    required bool usesGuardianPrimaryNavigation,
    required String currentLocation,
    required bool showShelterWorkspace,
  }) {
    final toggle = Padding(
      padding: EdgeInsets.only(left: isRoot ? 8 : 0),
      child: ExperienceWorkspaceToggle(
        currentLocation: currentLocation,
        onDarkBackground: usesGuardianPrimaryNavigation,
        showShelter: showShelterWorkspace,
      ),
    );

    if (isRoot) return toggle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('experience_back_button'),
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => _onBack(context),
        ),
        toggle,
      ],
    );
  }
}

/// Top chrome for the main content column when leading navigation is visible.
class _ContentChromeBar extends StatelessWidget {
  const _ContentChromeBar({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.leading,
    required this.leadingWidth,
    required this.title,
    required this.centerTitle,
    required this.actions,
  });

  final Color backgroundColor;
  final Color? foregroundColor;
  final Widget? leading;
  final double leadingWidth;
  final Widget title;
  final bool centerTitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const Key('experience_content_chrome'),
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: IconTheme.merge(
          data: IconThemeData(color: foregroundColor),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: foregroundColor),
            child: SizedBox(
              height: ExperienceShellScaffold._toolbarHeight,
              child: Row(
                children: [
                  if (leading != null)
                    SizedBox(
                      width: leadingWidth,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: leading,
                      ),
                    ),
                  Expanded(
                    child: centerTitle
                        ? Center(child: title)
                        : Align(alignment: Alignment.centerLeft, child: title),
                  ),
                  ...actions.map(
                    (action) => IconTheme.merge(
                      data: IconThemeData(
                        color: foregroundColor ?? theme.colorScheme.onSurface,
                      ),
                      child: action,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
