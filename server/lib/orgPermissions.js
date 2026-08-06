import { v4 as uuidv4 } from 'uuid';
import { logAuditEventSafe } from './audit.js';
import {
  ORG_ROLE_ADMIN,
  ORG_ROLE_ASSOCIATE,
  ORG_ROLE_SUPER_ADMIN,
  normaliseRole,
} from './orgRoles.js';

/**
 * G0 §7 permission keys — default role grants unioned with organization_permissions rows.
 * Each value is the set of org roles that receive the key by default.
 */
export const G0_PERMISSION_DEFAULTS = Object.freeze({
  // View keys (Organisation v2 — additive grants only)
  view_org_internal: Object.freeze([
    ORG_ROLE_SUPER_ADMIN,
    ORG_ROLE_ADMIN,
    ORG_ROLE_ASSOCIATE,
  ]),
  view_admin_contacts: Object.freeze([
    ORG_ROLE_SUPER_ADMIN,
    ORG_ROLE_ADMIN,
    ORG_ROLE_ASSOCIATE,
  ]),
  view_org_pets: Object.freeze([
    ORG_ROLE_SUPER_ADMIN,
    ORG_ROLE_ADMIN,
    ORG_ROLE_ASSOCIATE,
  ]),
  view_connections: Object.freeze([
    ORG_ROLE_SUPER_ADMIN,
    ORG_ROLE_ADMIN,
    ORG_ROLE_ASSOCIATE,
  ]),
  view_fostering_sessions: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_fosters: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  review_foster_onboarding: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  contact_fosters: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  confirm_foster_competencies: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_fostering_sessions: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  home_visits: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  adopter_screening: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_adoption_visits: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  start_adoption_journey: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  confirm_return_to_shelter: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_document_templates: Object.freeze([ORG_ROLE_SUPER_ADMIN]),
  manage_pets: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  transfer_pet_ownership: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_admin_contacts: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_members: Object.freeze([ORG_ROLE_SUPER_ADMIN, ORG_ROLE_ADMIN]),
  manage_permissions: Object.freeze([ORG_ROLE_SUPER_ADMIN]),
});

/** Organisation v2 view permission keys (subset of G0_PERMISSION_DEFAULTS). */
export const VIEW_PERMISSION_KEYS = Object.freeze([
  'view_org_internal',
  'view_admin_contacts',
  'view_org_pets',
  'view_connections',
  'view_fostering_sessions',
]);

export const PERMISSION_BUNDLE_FOSTER_ADMIN = 'foster_admin';
export const PERMISSION_BUNDLE_PET_ADMIN = 'pet_admin';
export const PERMISSION_BUNDLE_TEAM_ADMIN = 'team_admin';

/** @type {Readonly<Record<string, readonly string[]>>} */
export const PERMISSION_BUNDLE_KEYS = Object.freeze({
  [PERMISSION_BUNDLE_FOSTER_ADMIN]: Object.freeze([
    'manage_fosters',
    'review_foster_onboarding',
    'contact_fosters',
    'confirm_foster_competencies',
    'home_visits',
  ]),
  [PERMISSION_BUNDLE_PET_ADMIN]: Object.freeze([
    'manage_pets',
    'manage_fostering_sessions',
    'transfer_pet_ownership',
  ]),
  [PERMISSION_BUNDLE_TEAM_ADMIN]: Object.freeze([
    'manage_admin_contacts',
    'manage_members',
  ]),
});

const ACTIVE_PERMISSIONS_SQL = `
  SELECT permission_key
  FROM organization_permissions
  WHERE organization_id = $1
    AND user_id = $2
    AND revoked_at IS NULL
`;

const MEMBERSHIP_ROLE_SQL = `
  SELECT role
  FROM organization_users
  WHERE organization_id = $1
    AND user_id = $2
  LIMIT 1
`;

export function bundleSource(presetName) {
  return `bundle:${presetName}`;
}

export function hasRoleDefaultPermission(role, permissionKey) {
  const normalised = normaliseRole(role);
  const defaults = G0_PERMISSION_DEFAULTS[permissionKey];
  if (!defaults) return false;
  return defaults.includes(normalised);
}

export function hasEffectivePermission(role, activeOverrideKeys, permissionKey) {
  if (activeOverrideKeys.includes(permissionKey)) return true;
  return hasRoleDefaultPermission(role, permissionKey);
}

/**
 * Returns whether [role] has [permissionKey] under role defaults union optional overrides.
 * [org] may be null or `{ activePermissionKeys: string[] }`.
 */
export function hasPermission(role, org, permissionKey) {
  const overrideKeys = org?.activePermissionKeys ?? [];
  return hasEffectivePermission(role, overrideKeys, permissionKey);
}

export function permissionKeysForRole(role, activeOverrideKeys = []) {
  const defaults = Object.entries(G0_PERMISSION_DEFAULTS)
    .filter(([, roles]) => roles.includes(normaliseRole(role)))
    .map(([key]) => key);
  return [...new Set([...defaults, ...activeOverrideKeys])];
}

export async function loadActivePermissionKeys(pool, organizationId, userId) {
  const { rows } = await pool.query(ACTIVE_PERMISSIONS_SQL, [organizationId, userId]);
  return rows.map((row) => row.permission_key);
}

export async function loadMembershipRole(pool, organizationId, userId) {
  const { rows } = await pool.query(MEMBERSHIP_ROLE_SQL, [organizationId, userId]);
  return rows[0]?.role ?? null;
}

/** Route helper: effective permission for a user in an organisation. */
export async function hasPermissionForUser(pool, userId, organizationId, permissionKey) {
  const role = await loadMembershipRole(pool, organizationId, userId);
  if (!role || role.startsWith('pending_')) return false;

  const overrideKeys = await loadActivePermissionKeys(pool, organizationId, userId);
  return hasEffectivePermission(role, overrideKeys, permissionKey);
}

export async function grantPermission(
  pool,
  {
    organizationId,
    userId,
    permissionKey,
    grantedBy,
    source = 'individual',
    req = null,
  }
) {
  const id = uuidv4();
  const { rowCount } = await pool.query(
    `INSERT INTO organization_permissions (
      id, organization_id, user_id, permission_key, source, granted_by
    )
    SELECT $1::uuid, $2::uuid, $3::uuid, $4::varchar, $5::varchar, $6::uuid
    WHERE NOT EXISTS (
      SELECT 1
      FROM organization_permissions
      WHERE organization_id = $2::uuid
        AND user_id = $3::uuid
        AND permission_key = $4::varchar
        AND revoked_at IS NULL
    )`,
    [id, organizationId, userId, permissionKey, source, grantedBy]
  );
  if (rowCount > 0) {
    logAuditEventSafe(pool, {
      actorUserId: grantedBy,
      action: 'permission_granted',
      resourceType: 'organization_permission',
      resourceId: id,
      orgId: organizationId,
      metadata: {
        user_id: userId,
        permission_key: permissionKey,
        source,
      },
      req,
    });
  }
  return rowCount > 0 ? id : null;
}

export async function revokePermission(
  pool,
  { organizationId, userId, permissionKey, revokedBy, req = null }
) {
  const { rows, rowCount } = await pool.query(
    `UPDATE organization_permissions
     SET revoked_at = NOW(), revoked_by = $4
     WHERE organization_id = $1
       AND user_id = $2
       AND permission_key = $3
       AND revoked_at IS NULL
     RETURNING id`,
    [organizationId, userId, permissionKey, revokedBy]
  );
  if (rowCount > 0) {
    logAuditEventSafe(pool, {
      actorUserId: revokedBy,
      action: 'permission_revoked',
      resourceType: 'organization_permission',
      resourceId: rows[0]?.id ?? null,
      orgId: organizationId,
      metadata: {
        user_id: userId,
        permission_key: permissionKey,
      },
      req,
    });
  }
  return rowCount > 0;
}

export async function applyBundlePreset(
  pool,
  { organizationId, userId, presetName, grantedBy, req = null }
) {
  const keys = PERMISSION_BUNDLE_KEYS[presetName];
  if (!keys) {
    throw new Error(`Unknown permission bundle preset: ${presetName}`);
  }
  const source = bundleSource(presetName);
  let grantedCount = 0;
  for (const permissionKey of keys) {
    const id = await grantPermission(pool, {
      organizationId,
      userId,
      permissionKey,
      grantedBy,
      source,
      req,
    });
    if (id) grantedCount += 1;
  }
  if (grantedCount > 0) {
    logAuditEventSafe(pool, {
      actorUserId: grantedBy,
      action: 'bundle_preset_applied',
      resourceType: 'organization_permission_bundle',
      resourceId: presetName,
      orgId: organizationId,
      metadata: {
        user_id: userId,
        preset_name: presetName,
        permission_keys: keys,
        granted_count: grantedCount,
      },
      req,
    });
  }
  return grantedCount;
}
