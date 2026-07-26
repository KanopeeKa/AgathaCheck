import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/organization_member.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/admin_contact_providers.dart';

/// Shows [child] only when the viewer has [permissionKey] in this organisation.
class OrgPermissionGate extends ConsumerWidget {
  const OrgPermissionGate({
    super.key,
    required this.orgId,
    required this.permissionKey,
    required this.child,
  });

  final String orgId;
  final String permissionKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(orgViewerRoleProvider(orgId));
    if (!_can(role)) return const SizedBox.shrink();
    return child;
  }

  bool _can(OrgMemberRole? role) {
    if (role == null) return false;
    return hasPermission(role, orgId, permissionKey);
  }
}
