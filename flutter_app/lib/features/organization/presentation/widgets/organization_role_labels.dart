import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/organization_member.dart';

String localizedOrgMemberRole(AppLocalizations l, OrgMemberRole role) {
  if (role.isPending) return l.invited;
  switch (role) {
    case OrgMemberRole.superAdmin:
      return l.orgSuperAdmin;
    case OrgMemberRole.admin:
      return l.orgAdmin;
    case OrgMemberRole.foster:
      return l.orgAssociate;
    case OrgMemberRole.associate:
      return l.orgAssociate;
    case OrgMemberRole.pendingSuperAdmin:
    case OrgMemberRole.pendingAdmin:
    case OrgMemberRole.pendingFoster:
    case OrgMemberRole.pendingAssociate:
      return l.invited;
  }
}

String localizedOrgRoleWire(AppLocalizations l, String wireRole) {
  return localizedOrgMemberRole(l, OrgMemberRole.fromWire(wireRole));
}

List<String> invitableRoleWires({required bool isSuperAdmin}) {
  if (isSuperAdmin) {
    return ['super_admin', 'admin', 'associate'];
  }
  return ['admin', 'associate'];
}

String invitableRoleLabel(AppLocalizations l, String wireRole) {
  return localizedOrgRoleWire(l, wireRole);
}
