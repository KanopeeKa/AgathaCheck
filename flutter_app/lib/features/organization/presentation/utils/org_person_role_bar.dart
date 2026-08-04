import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
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

/// Role bar colours per D-v3-TILE-2.
OrgPersonRoleBarStyle orgPersonRoleBarStyle(
  BuildContext context, {
  required OrgMemberRole? role,
  required bool isExternal,
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

  final effectiveRole = isExternal ? OrgMemberRole.foster : role;

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
    case OrgMemberRole.foster:
      return OrgPersonRoleBarStyle(
        barColor: AppColorTokens.organizationSoft,
        labelColor: xp.organizationPrimary,
      );
    case OrgMemberRole.associate:
      return OrgPersonRoleBarStyle(
        barColor: Colors.white,
        labelColor: colorScheme.onSurface,
        borderColor: colorScheme.outlineVariant,
      );
    case null:
      return OrgPersonRoleBarStyle(
        barColor: colorScheme.outlineVariant,
        labelColor: colorScheme.onSurfaceVariant,
      );
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
