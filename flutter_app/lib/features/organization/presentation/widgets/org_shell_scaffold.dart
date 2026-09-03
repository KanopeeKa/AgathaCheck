import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/widgets/shell_notification_bell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/utils/experience_theme.dart';
import '../../../experience/presentation/widgets/experience_workspace_toggle.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import '../utils/org_screen_theme.dart';
import 'org_shell_app_bar_title.dart';

/// Organisation-area scaffold: teal background, adaptive nav title, bell (D-v3-NAV-1).
///
/// Includes [ExperienceWorkspaceToggle] on every route (D-v5-WORKSPACE-4, D-desk-S4).
class OrgShellScaffold extends ConsumerWidget {
  const OrgShellScaffold({
    super.key,
    required this.title,
    required this.child,
    this.navVariant = OrgNavTitleVariant.textOnly,
    this.organization,
    this.orgId,
    this.contextualActions = const [],
    this.trailingActions = const [],
    this.onBack,
    this.backPath,
    this.leadingKey,
    this.scaffoldKey,
    this.endDrawer,
    this.showBackButton = true,
    this.floatingActionButton,
    this.currentLocation,
  });

  final String title;
  final Widget child;
  final OrgNavTitleVariant navVariant;
  final Organization? organization;
  final String? orgId;
  final List<Widget> contextualActions;
  final List<Widget> trailingActions;
  final VoidCallback? onBack;
  final String? backPath;
  final Key? leadingKey;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? endDrawer;
  final bool showBackButton;
  final Widget? floatingActionButton;

  /// Route path for workspace toggle highlighting; defaults to [GoRouter] location.
  final String? currentLocation;

  static const _workspaceToggleWidth = 184.0;
  static const _backButtonWidth = 48.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellTheme = themeForAppExperience(theme, AppExperience.organization);
    final resolvedOrg = _resolveOrganization(ref);
    final location = currentLocation ??
        GoRouter.maybeOf(context)?.state.uri.path ??
        '/o/orgs';
    final leadingWidth = showBackButton
        ? _workspaceToggleWidth + _backButtonWidth
        : _workspaceToggleWidth;

    return Theme(
      data: shellTheme,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: orgListScaffoldBackground(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: leadingWidth,
          leading: _buildLeading(context, l, location),
          centerTitle: true,
          title: OrgShellAppBarTitle(
            title: title,
            variant: navVariant,
            organization: resolvedOrg,
          ),
          actions: [
            ...contextualActions,
            ...trailingActions,
            if (contextualActions.isNotEmpty || trailingActions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '|',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Builder(builder: (ctx) => const ShellNotificationBell()),
          ],
        ),
        endDrawer: endDrawer ?? const NotificationPanel(),
        floatingActionButton: floatingActionButton,
        body: child,
      ),
    );
  }

  Widget _buildLeading(
    BuildContext context,
    AppLocalizations l,
    String location,
  ) {
    final toggle = Padding(
      padding: EdgeInsets.only(left: showBackButton ? 0 : 8),
      child: ExperienceWorkspaceToggle(
        key: const Key('org_shell_workspace_toggle'),
        currentLocation: location,
        onDarkBackground: false,
        showShelter: true,
      ),
    );

    if (!showBackButton) return toggle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: leadingKey ?? const Key('org_shell_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: onBack ?? () => _defaultBack(context),
        ),
        toggle,
      ],
    );
  }

  Organization? _resolveOrganization(WidgetRef ref) {
    if (navVariant != OrgNavTitleVariant.withOrgLogo) return null;
    if (organization != null) return organization;
    final id = orgId;
    if (id == null) return null;
    return ref
        .watch(organizationListProvider)
        .maybeWhen(
          data: (orgs) => orgs.where((o) => o.id == id).firstOrNull,
          orElse: () => null,
        );
  }

  void _defaultBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    final destination = backPath ?? '/o/orgs';
    context.go(destination);
  }
}
