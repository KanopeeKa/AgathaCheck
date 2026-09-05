import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../domain/entities/organization.dart';
import '../providers/organization_providers.dart';
import 'org_shell_app_bar_title.dart';

/// Organisation deep-route scaffold — delegates to [ExperienceShellScaffold]
/// so Shelter primary nav (bottom / rail / sidebar) persists on `/o/**` routes.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedOrg = _resolveOrganization(ref);
    final location =
        currentLocation ??
        GoRouter.maybeOf(context)?.state.uri.path ??
        '/o/orgs';

    return ExperienceShellScaffold(
      experience: AppExperience.organization,
      currentLocation: location,
      screenTitle: title,
      orgNavVariant: navVariant,
      organization: resolvedOrg ?? organization,
      contextualActions: [...contextualActions, ...trailingActions],
      backPath: backPath,
      onBackPressed: onBack,
      backButtonKey: showBackButton
          ? (leadingKey ?? const Key('org_shell_back'))
          : null,
      scaffoldKey: scaffoldKey,
      floatingActionButton: floatingActionButton,
      child: child,
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
}
