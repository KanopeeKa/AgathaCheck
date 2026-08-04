import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/shell_notification_bell.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/utils/experience_theme.dart';
import '../../../notifications/presentation/widgets/notification_panel.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import '../utils/org_screen_theme.dart';
import 'org_shell_app_bar_title.dart';

/// Organisation-area scaffold: teal background, adaptive nav title, bell (D-v3-NAV-1).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellTheme = themeForAppExperience(theme, AppExperience.organization);
    final resolvedOrg = _resolveOrganization(ref);

    return Theme(
      data: shellTheme,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: orgListScaffoldBackground(context),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: showBackButton
              ? IconButton(
                  key: leadingKey,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l.goBack,
                  onPressed: onBack ?? () => _defaultBack(context),
                )
              : null,
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
