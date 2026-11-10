import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/shell_notification_bell.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../notifications/notifications.dart';
import '../services/notification_inline_action_runner.dart';
import '../../domain/entities/app_experience.dart';
import '../config/drawer_menu_config.dart';
import '../utils/experience_theme.dart';
import 'experience_section_drawer.dart';
import '../config/pet_care_primary_destinations.dart';
import 'pet_care_bottom_navigation.dart';
import 'pet_care_navigation_rail.dart';
import 'pet_care_navigation_sidebar.dart';
import 'experience_shell_chrome_bar.dart';

/// Shell scaffold for Pet Care experience screens.
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
    this.onBackPressed,
    this.backButtonKey,
    this.scaffoldKey,
    this.floatingActionButton,
  });

  final AppExperience experience;
  final String currentLocation;
  final Widget child;
  final String? screenTitle;
  final List<Widget> contextualActions;
  final String? backPath;
  final bool forceBackPath;
  final VoidCallback? onBackPressed;
  final Key? backButtonKey;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? floatingActionButton;

  static const _toolbarHeight = 64.0;

  bool _isRoot() => DrawerMenuConfig.sectionRootPaths.contains(currentLocation);

  String _sectionRoot() => AppExperience.petCare.homePath();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellTheme = themeForAppExperience(theme, AppExperience.petCare);
    final isRoot = _isRoot();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final usesPetCarePrimaryNavigation = PetCarePrimaryDestinations.isCompact(
      viewportWidth,
    );
    final usesPetCareNavigationSidebar = PetCarePrimaryDestinations.isExpanded(
      viewportWidth,
    );
    final usesPetCareNavigationRail = PetCarePrimaryDestinations.isMedium(
      viewportWidth,
    );
    final usesPetCareLeadingNav =
        usesPetCareNavigationRail || usesPetCareNavigationSidebar;
    final usesCompactShellWithoutHamburger = usesPetCarePrimaryNavigation;
    final appBarColor = usesPetCarePrimaryNavigation
        ? AppColorTokens.petCarePrimary
        : AppColorTokens.background;
    final appBarForeground = usesPetCarePrimaryNavigation
        ? AppColorTokens.inverse
        : null;
    final leadingWidth = usesPetCareLeadingNav
        ? (isRoot ? null : 56.0)
        : (isRoot ? 0.0 : 56.0);
    final hideTitleForAccessibleCompactHeader =
        isRoot &&
        MediaQuery.sizeOf(context).width < 360 &&
        MediaQuery.textScalerOf(context).scale(14) > 18;
    final suppressSectionRootAppBarTitle = usesPetCareLeadingNav && isRoot;
    final usesDesktopContentHeader =
        usesPetCareLeadingNav && !suppressSectionRootAppBarTitle;
    final showTitle =
        screenTitle != null &&
        !hideTitleForAccessibleCompactHeader &&
        !suppressSectionRootAppBarTitle;
    final centerAppBarTitle =
        !usesDesktopContentHeader && !usesCompactShellWithoutHamburger;
    final titleWidget = !showTitle
        ? const SizedBox.shrink()
        : usesDesktopContentHeader
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
            experience: AppExperience.petCare,
            useShellLogo: usesPetCarePrimaryNavigation,
          );
    final trailingActions = _buildTrailingActions(
      theme: theme,
      usesPetCarePrimaryNavigation: usesPetCarePrimaryNavigation,
    );
    final leadingWidget = usesPetCareLeadingNav
        ? (!isRoot
              ? IconButton(
                  key: backButtonKey ?? const Key('experience_back_button'),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: () => _onBack(context),
                )
              : null)
        : _buildCompactShellLeading(context: context, l: l, isRoot: isRoot);

    return Theme(
      data: shellTheme,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppColorTokens.background,
        appBar: usesPetCareLeadingNav
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
                leading: usesCompactShellWithoutHamburger && isRoot
                    ? null
                    : leadingWidget,
                centerTitle: centerAppBarTitle,
                title: titleWidget,
                actions: trailingActions,
              ),
        drawer: usesPetCareLeadingNav ? null : const ExperienceSectionDrawer(),
        endDrawer: Consumer(
          builder: (context, ref, _) => ProviderScope(
            overrides: [
              notificationInlineActionsProvider.overrideWithValue(
                NotificationInlineActionRunner(ref),
              ),
            ],
            child: const NotificationPanel(),
          ),
        ),
        floatingActionButton: floatingActionButton,
        body: usesPetCareLeadingNav
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (usesPetCareNavigationSidebar)
                    PetCareNavigationSidebar(currentLocation: currentLocation)
                  else
                    PetCareNavigationRail(currentLocation: currentLocation),
                  Expanded(
                    child: Material(
                      key: const Key('experience_workspace_canvas'),
                      color: AppColorTokens.background,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ExperienceContentChromeBar(
                            toolbarHeight: _toolbarHeight,
                            backgroundColor: appBarColor,
                            foregroundColor: appBarForeground,
                            leading: leadingWidget,
                            leadingWidth: leadingWidth ?? 56,
                            title: titleWidget,
                            centerTitle: centerAppBarTitle,
                            actions: trailingActions,
                          ),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : child,
        bottomNavigationBar: usesPetCarePrimaryNavigation
            ? PetCareBottomNavigation(currentLocation: currentLocation)
            : null,
      ),
    );
  }

  List<Widget> _buildTrailingActions({
    required ThemeData theme,
    required bool usesPetCarePrimaryNavigation,
  }) {
    return [
      if (contextualActions.isNotEmpty) ...contextualActions,
      if (contextualActions.isNotEmpty)
        VerticalDivider(
          width: 16,
          indent: 18,
          endIndent: 18,
          color: usesPetCarePrimaryNavigation
              ? AppColorTokens.petCareLight
              : theme.colorScheme.outlineVariant,
        ),
      Builder(builder: (ctx) => const ShellNotificationBell()),
    ];
  }

  void _onBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }
    final returnTo = shellReturnToFromState(GoRouterState.of(context));
    handleShellBack(
      context,
      backPath: backPath,
      returnTo: returnTo,
      defaultPath: backPath ?? _sectionRoot(),
      forceBackPath: forceBackPath,
    );
  }

  Widget? _buildCompactShellLeading({
    required BuildContext context,
    required AppLocalizations l,
    required bool isRoot,
  }) {
    if (isRoot) {
      return null;
    }

    return IconButton(
      key: backButtonKey ?? const Key('experience_back_button'),
      icon: const Icon(Icons.arrow_back),
      tooltip: l.goBack,
      onPressed: () => _onBack(context),
    );
  }
}
