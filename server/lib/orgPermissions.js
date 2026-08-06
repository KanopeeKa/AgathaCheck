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

export const EDITABLE_ROLE_TIERS = Object.freeze(['associate', 'admin']);
export const ROLE_TIER_SUPER_ADMIN = 'super_admin';

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

const ORG_ROLE_DEFAULTS_SQL = `
  SELECT role_tier, permission_key, granted
  FROM organization_role_permission_defaults
  WHERE organization_id = $1
`;

export function bundleSource(presetName) {
  return `bundle:${presetName}`;
}

export function roleForTier(roleTier) {
  switch (roleTier) {
    case 'associate':
      return ORG_ROLE_ASSOCIATE;
    case 'admin':
      return ORG_ROLE_ADMIN;
    case ROLE_TIER_SUPER_ADMIN:
      return ORG_ROLE_SUPER_ADMIN;
    default:
      return null;
  }
}

export function roleTierForRole(role) {
  const normalised = normaliseRole(role);
  if (normalised === ORG_ROLE_SUPER_ADMIN) return ROLE_TIER_SUPER_ADMIN;
  if (normalised === ORG_ROLE_ADMIN) return 'admin';
  if (normalised === ORG_ROLE_ASSOCIATE) return 'associate';
  return null;
}

export function g0KeysForRole(role) {
  const normalised = normaliseRole(role);
  return Object.entries(G0_PERMISSION_DEFAULTS)
    .filter(([, roles]) => roles.includes(normalised))
    .map(([key]) => key);
}

export function effectiveTierDefaultKeys(roleTier, orgRows = []) {
  const role = roleForTier(roleTier);
  if (!role) return [];
  const effective = new Set(g0KeysForRole(role));
  for (const row of orgRows) {
    if (row.role_tier !== roleTier) continue;
    if (row.granted) {
      effective.add(row.permission_key);
    } else {
      effective.delete(row.permission_key);
    }
  }
  return [...effective];
}

export function tierDefaultRowsFromGrantedKeys(roleTier, grantedKeys) {
  const role = roleForTier(roleTier);
  if (!role) return [];
  const g0Set = new Set(g0KeysForRole(role));
  const grantedSet = new Set(grantedKeys);
  const rows = [];
  for (const key of Object.keys(G0_PERMISSION_DEFAULTS)) {
    const inG0 = g0Set.has(key);
    const granted = grantedSet.has(key);
    if (inG0 !== granted) {
      rows.push({ role_tier: roleTier, permission_key: key, granted });
    }
  }
  return rows;
}

export function hasRoleDefaultPermission(role, permissionKey) {
  const normalised = normaliseRole(role);
  const defaults = G0_PERMISSION_DEFAULTS[permissionKey];
  if (!defaults) return false;
  return defaults.includes(normalised);
}

export function hasEffectivePermission(
  role,
  activeOverrideKeys,
  permissionKey,
  orgRows = [],
) {
  if (activeOverrideKeys.includes(permissionKey)) return true;
  const tier = roleTierForRole(role);
  if (tier) {
    return effectiveTierDefaultKeys(tier, orgRows).includes(permissionKey);
  }
  return hasRoleDefaultPermission(role, permissionKey);
}

/**
 * Returns whether [role] has [permissionKey] under role defaults union optional overrides.
 * [org] may be null or `{ activePermissionKeys: string[] }`.
 */
export function hasPermission(role, org, permissionKey) {
  const overrideKeys = org?.activePermissionKeys ?? [];
  const orgRows = org?.rolePermissionDefaults ?? [];
  return hasEffectivePermission(role, overrideKeys, permissionKey, orgRows);
}

export function permissionKeysForRole(role, activeOverrideKeys = [], orgRows = []) {
  const tier = roleTierForRole(role);
  const defaults = tier
    ? effectiveTierDefaultKeys(tier, orgRows)
    : g0KeysForRole(role);
  return [...new Set([...defaults, ...activeOverrideKeys])];
}

export async function loadActivePermissionKeys(pool, organizationId, userId) {
  const { rows } = await pool.query(ACTIVE_PERMISSIONS_SQL, [organizationId, userId]);
  return rows.map((row) => row.permission_key);
}

export async function loadOrgRolePermissionDefaults(pool, organizationId) {
  const { rows } = await pool.query(ORG_ROLE_DEFAULTS_SQL, [organizationId]);
  return rows;
}

export function buildRolePermissionDefaultsResponse(orgRows = []) {
  const tiers = {};
  for (const roleTier of [...EDITABLE_ROLE_TIERS, ROLE_TIER_SUPER_ADMIN]) {
    const g0Defaults = g0KeysForRole(roleForTier(roleTier));
    const orgOverrides = orgRows
      .filter((row) => row.role_tier === roleTier)
      .map((row) => ({
        permission_key: row.permission_key,
        granted: row.granted,
      }));
    tiers[roleTier] = {
      editable: EDITABLE_ROLE_TIERS.includes(roleTier),
      g0_defaults: g0Defaults,
      org_overrides: orgOverrides,
      effective_defaults: effectiveTierDefaultKeys(roleTier, orgRows),
    };
  }
  return {
    tiers,
    permission_keys: Object.keys(G0_PERMISSION_DEFAULTS),
  };
}

export async function saveOrgRolePermissionDefaults(
  pool,
  { organizationId, roleTier, grantedKeys, savedBy, req = null },
) {
  if (!EDITABLE_ROLE_TIERS.includes(roleTier)) {
    throw new Error(`Role tier is not editable: ${roleTier}`);
  }

  const deltaRows = tierDefaultRowsFromGrantedKeys(roleTier, grantedKeys);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `DELETE FROM organization_role_permission_defaults
       WHERE organization_id = $1 AND role_tier = $2`,
      [organizationId, roleTier],
    );
    for (const row of deltaRows) {
      await client.query(
        `INSERT INTO organization_role_permission_defaults (
          organization_id, role_tier, permission_key, granted
        ) VALUES ($1, $2, $3, $4)`,
        [organizationId, row.role_tier, row.permission_key, row.granted],
      );
    }

    const role = roleForTier(roleTier);
    const { rows: members } = await client.query(
      `SELECT user_id
       FROM organization_users
       WHERE organization_id = $1
         AND role = $2`,
      [organizationId, role],
    );

    const effectiveKeys = effectiveTierDefaultKeys(roleTier, deltaRows);
    const g0Set = new Set(g0KeysForRole(role));
    for (const { user_id: memberUserId } of members) {
      const { rows: overrideRows } = await client.query(ACTIVE_PERMISSIONS_SQL, [
        organizationId,
        memberUserId,
      ]);
      for (const override of overrideRows) {
        const key = override.permission_key;
        if (effectiveKeys.includes(key) && g0Set.has(key)) {
          await client.query(
            `UPDATE organization_permissions
             SET revoked_at = NOW(), revoked_by = $4
             WHERE organization_id = $1
               AND user_id = $2
               AND permission_key = $3
               AND revoked_at IS NULL`,
            [organizationId, memberUserId, key, savedBy],
          );
        }
      }
    }

    logAuditEventSafe(client, {
      actorUserId: savedBy,
      action: 'org_tier_defaults_updated',
      resourceType: 'organization_role_permission_defaults',
      resourceId: roleTier,
      orgId: organizationId,
      metadata: {
        role_tier: roleTier,
        override_count: deltaRows.length,
        members_affected: members.length,
      },
      req,
    });

    await client.query('COMMIT');

    return {
      tier: roleTier,
      editable: true,
      g0_defaults: g0KeysForRole(role),
      org_overrides: deltaRows.map((row) => ({
        permission_key: row.permission_key,
        granted: row.granted,
      })),
      effective_defaults: [...grantedKeys],
      members_affected: members.length,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function loadMembershipRole(pool, organizationId, userId) {
  const { rows } = await pool.query(MEMBERSHIP_ROLE_SQL, [organizationId, userId]);
  return rows[0]?.role ?? null;
}

/** Route helper: effective permission for a user in an organisation. */
export async function hasPermissionForUser(pool, userId, organizationId, permissionKey) {
  const role = await loadMembershipRole(pool, organizationId, userId);
  if (!role || role.startsWith('pending_')) return false;

  const [overrideKeys, orgRows] = await Promise.all([
    loadActivePermissionKeys(pool, organizationId, userId),
    loadOrgRolePermissionDefaults(pool, organizationId),
  ]);
  return hasEffectivePermission(role, overrideKeys, permissionKey, orgRows);
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
