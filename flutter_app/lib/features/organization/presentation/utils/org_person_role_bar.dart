import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/organization_member.dart';

/// Resolved colours for the role separator bar on [OrgPersonTile].
class OrgPersonRoleBarStyle {
  const OrgPersonRoleBarStyle({
    required this.barColor,
    required this.labelColor,
    this.borderColor,
  });

  final Color barColor;
  final Color labelColor;
  final Color? borderColor;
}

/// Whether the wire-role bar should render for this person (D-v4-ROLE-1).
bool shouldShowOrgPersonRoleBar({
  required OrgMemberRole? role,
  required bool isPending,
}) {
  if (isPending || (role?.isPending ?? false)) return true;
  if (role == null) return false;
  return role == OrgMemberRole.superAdmin ||
      role == OrgMemberRole.admin ||
      role == OrgMemberRole.associate ||
      role == OrgMemberRole.foster;
}

/// Role bar colours for associate / admin / super_admin wire tiers only.
OrgPersonRoleBarStyle orgPersonRoleBarStyle(
  BuildContext context, {
  required OrgMemberRole? role,
  required bool isPending,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final xp = context.experienceColors;

  if (isPending || (role?.isPending ?? false)) {
    return OrgPersonRoleBarStyle(
      barColor: colorScheme.outlineVariant,
      labelColor: colorScheme.onSurfaceVariant,
    );
  }

  final effectiveRole = role == OrgMemberRole.foster
      ? OrgMemberRole.associate
      : role;

  switch (effectiveRole) {
    case OrgMemberRole.superAdmin:
      return const OrgPersonRoleBarStyle(
        barColor: Colors.black,
        labelColor: Colors.white,
      );
    case OrgMemberRole.admin:
      return OrgPersonRoleBarStyle(
        barColor: xp.organizationPrimary,
        labelColor: xp.organizationOnPrimary,
      );
    case OrgMemberRole.associate:
      return OrgPersonRoleBarStyle(
        barColor: Colors.white,
        labelColor: colorScheme.onSurface,
        borderColor: colorScheme.outlineVariant,
      );
    case null:
    case OrgMemberRole.foster:
    case OrgMemberRole.pendingSuperAdmin:
    case OrgMemberRole.pendingAdmin:
    case OrgMemberRole.pendingFoster:
    case OrgMemberRole.pendingAssociate:
      return OrgPersonRoleBarStyle(
        barColor: colorScheme.outlineVariant,
        labelColor: colorScheme.onSurfaceVariant,
      );
  }
}
