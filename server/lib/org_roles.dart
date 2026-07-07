/// Organisation membership roles and permission helpers (parity with orgRoles.js).

const orgRoleSuperAdmin = 'super_admin';
const orgRoleAdmin = 'admin';
const orgRoleFoster = 'foster';

const assignableOrgRoles = [
  orgRoleSuperAdmin,
  orgRoleAdmin,
  orgRoleFoster,
];

const fosterParentMemberRoles = [
  orgRoleSuperAdmin,
  orgRoleAdmin,
  orgRoleFoster,
];

String fosterParentMemberRolesSql() =>
    fosterParentMemberRoles.map((r) => "'$r'").join(', ');

bool isActiveOrgMemberRole(String? role) =>
    role != null && !role.startsWith('pending_');

bool isOrgSuperAdmin(String? role) => role == orgRoleSuperAdmin;

bool isOrgAdminRole(String? role) =>
    role == orgRoleSuperAdmin || role == orgRoleAdmin;

bool isFosterParentMemberRole(String? role) {
  final normalised = normaliseOrgRole(role);
  return fosterParentMemberRoles.contains(normalised);
}

List<String> assignableRolesFor(String? actorRole) {
  if (isOrgSuperAdmin(actorRole)) return [...assignableOrgRoles];
  if (isOrgAdminRole(actorRole)) return [orgRoleAdmin, orgRoleFoster];
  return [];
}

bool canAssignOrgRole(String? actorRole, String targetRole) =>
    assignableRolesFor(actorRole).contains(targetRole);

String normaliseOrgRole(String? role) {
  switch (role) {
    case 'super_user':
    case 'member':
      return orgRoleSuperAdmin;
    case 'pending_super_user':
    case 'pending_member':
      return 'pending_$orgRoleSuperAdmin';
    default:
      return role ?? '';
  }
}
