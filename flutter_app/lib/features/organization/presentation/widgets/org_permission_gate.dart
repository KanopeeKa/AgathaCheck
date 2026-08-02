import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/org_permissions.dart';
import '../providers/org_permissions_providers.dart';

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
    final permissions = ref.watch(orgEffectivePermissionsProvider(orgId));
    return permissions.when(
      data: (keys) => keys.contains(permissionKey)
          ? child
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
