/**
 * Organisation membership roles and permission helpers.
 * Wire values are stored in organization_users.role.
 */

export const ORG_ROLE_SUPER_ADMIN = 'super_admin';
export const ORG_ROLE_ADMIN = 'admin';
/** Legacy wire value — normalises to associate; not assignable after v4 Phase C. */
export const ORG_ROLE_FOSTER = 'foster';
export const ORG_ROLE_ASSOCIATE = 'associate';

export const ASSIGNABLE_ROLES = [
  ORG_ROLE_SUPER_ADMIN,
  ORG_ROLE_ADMIN,
  ORG_ROLE_ASSOCIATE,
];

/** Roles that may view all pets tagged to the organisation (includes legacy wire values). */
export const ORG_PET_VIEWER_ROLES = [
  ORG_ROLE_SUPER_ADMIN,
  ORG_ROLE_ADMIN,
  'super_user',
  'member',
];

const ORG_PET_VIEWER_ROLES_SQL = ORG_PET_VIEWER_ROLES.map((r) => `'${r}'`).join(', ');

export function orgPetViewerRolesSql() {
  return ORG_PET_VIEWER_ROLES_SQL;
}

export function isActiveMember(role) {
  return !!role && !role.startsWith('pending_');
}

export function isSuperAdmin(role) {
  return role === ORG_ROLE_SUPER_ADMIN;
}

/** Super admin or admin — org management except edit/delete org (super admin only). */
export function isOrgAdmin(role) {
  return role === ORG_ROLE_SUPER_ADMIN || role === ORG_ROLE_ADMIN;
}

export function isFoster(role) {
  return role === ORG_ROLE_FOSTER;
}

export function isAssociate(role) {
  const normalised = normaliseRole(role);
  return normalised === ORG_ROLE_ASSOCIATE;
}

/** Org members who may appear in the foster parent directory by wire role (Inc 3+). */
export const FOSTER_PARENT_MEMBER_ROLES = [
  ORG_ROLE_SUPER_ADMIN,
  ORG_ROLE_ADMIN,
];

const FOSTER_PARENT_MEMBER_ROLES_SQL = FOSTER_PARENT_MEMBER_ROLES.map((r) => `'${r}'`).join(', ');

export function fosterParentMemberRolesSql() {
  return FOSTER_PARENT_MEMBER_ROLES_SQL;
}

export function isFosterParentMember(role) {
  const normalised = normaliseRole(role);
  return FOSTER_PARENT_MEMBER_ROLES.includes(normalised);
}

/**
 * Whether a user is a foster parent for an organisation (wire role or shelter relationship).
 * @param {import('pg').Pool} pool
 * @param {string} orgId
 * @param {string} userId
 */
export async function isOrgFosterParent(pool, orgId, userId) {
  const member = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  if (member.rows.length === 0) return false;
  if (isFosterParentMember(member.rows[0].role)) return true;
  const rel = await pool.query(
    `SELECT 1 FROM org_foster_parents
     WHERE organization_id = $1 AND user_id = $2 AND opt_out_at IS NULL
     LIMIT 1`,
    [orgId, userId],
  );
  return rel.rows.length > 0;
}

/** Roles the actor may assign when inviting or changing membership. */
export function assignableRolesFor(actorRole) {
  if (isSuperAdmin(actorRole)) return [...ASSIGNABLE_ROLES];
  if (isOrgAdmin(actorRole)) return [ORG_ROLE_ADMIN, ORG_ROLE_ASSOCIATE];
  return [];
}

export function canAssignRole(actorRole, targetRole) {
  return assignableRolesFor(actorRole).includes(targetRole);
}

/** Normalise legacy role strings (pre-migration) for permission checks. */
export function normaliseRole(role) {
  switch (role) {
    case 'super_user':
      return ORG_ROLE_SUPER_ADMIN;
    case 'member':
      return ORG_ROLE_SUPER_ADMIN;
    case 'pending_super_user':
    case 'pending_member':
      return `pending_${ORG_ROLE_SUPER_ADMIN}`;
    case ORG_ROLE_FOSTER:
      return ORG_ROLE_ASSOCIATE;
    case 'pending_foster':
      return `pending_${ORG_ROLE_ASSOCIATE}`;
    default:
      return role;
  }
}
