import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/dashboard_section.dart';
import '../../providers/org_permissions_providers.dart';
import '../org_permission_gate.dart';

/// Profile section shell with [permissionKey] gate, title, preview, and optional manage link.
class OrganisationProfileSection extends ConsumerWidget {
  const OrganisationProfileSection({
    super.key,
    required this.orgId,
    required this.permissionKey,
    required this.title,
    required this.preview,
    this.manageLinkLabel,
    this.onManage,
    this.managePermissionKey,
    this.sectionKey,
  });

  final String orgId;
  final String permissionKey;
  final String title;
  final Widget preview;
  final String? manageLinkLabel;
  final VoidCallback? onManage;
  final String? managePermissionKey;
  final Key? sectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrgPermissionGate(
      orgId: orgId,
      permissionKey: permissionKey,
      child: KeyedSubtree(
        key: sectionKey,
        child: _OrganisationProfileSectionBody(
          orgId: orgId,
          title: title,
          preview: preview,
          manageLinkLabel: manageLinkLabel,
          onManage: onManage,
          managePermissionKey: managePermissionKey,
        ),
      ),
    );
  }
}

class _OrganisationProfileSectionBody extends ConsumerWidget {
  const _OrganisationProfileSectionBody({
    required this.orgId,
    required this.title,
    required this.preview,
    this.manageLinkLabel,
    this.onManage,
    this.managePermissionKey,
  });

  final String orgId;
  final String title;
  final Widget preview;
  final String? manageLinkLabel;
  final VoidCallback? onManage;
  final String? managePermissionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manageLink = _resolveManageLink(ref);

    return DashboardSection(
      title: title,
      previewBuilder: (_) => preview,
      endLink: manageLink,
    );
  }

  DashboardSectionLink? _resolveManageLink(WidgetRef ref) {
    final label = manageLinkLabel;
    final onPressed = onManage;
    if (label == null || onPressed == null) return null;

    final manageKey = managePermissionKey;
    if (manageKey == null) {
      return DashboardSectionLink(label: label, onPressed: onPressed);
    }

    final permissions = ref.watch(orgEffectivePermissionsProvider(orgId));
    return permissions.maybeWhen(
      data: (keys) => keys.contains(manageKey)
          ? DashboardSectionLink(label: label, onPressed: onPressed)
          : null,
      orElse: () => null,
    );
  }
}
