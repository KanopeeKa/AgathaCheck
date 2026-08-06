import {
  applyBundlePreset,
  applyPermissionBatch,
  G0_PERMISSION_DEFAULTS,
  grantPermission,
  loadActivePermissionKeys,
  loadMembershipRole,
  PERMISSION_BUNDLE_KEYS,
  permissionKeysForRole,
  revokePermission,
} from '../../lib/orgPermissions.js';
import { pseudonymizeActor } from '../../lib/audit.js';
import { publicError } from '../../config/security.js';
import { extractUserId, requirePermission } from './shared.js';

const AUDIT_EVENT_LIMIT = 100;

const SAFE_AUDIT_METADATA_KEYS = new Set([
  'user_id',
  'permission_key',
  'permission_keys',
  'source',
  'preset_name',
  'granted_count',
  'fields',
  'role',
  'previous_role',
  'new_role',
  'outcome',
  'visit_outcome',
  'confirmation',
]);

function safeAuditMetadata(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {};
  const safe = {};
  for (const [key, value] of Object.entries(raw)) {
    if (!SAFE_AUDIT_METADATA_KEYS.has(key)) continue;
    if (key === 'permission_keys' && Array.isArray(value)) {
      safe[key] = value.filter((entry) => typeof entry === 'string');
      continue;
    }
    if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
      safe[key] = value;
    }
  }
  return safe;
}

function auditEventToMap(row) {
  const actorUserId =
    row.retention_tier === 'hot' && row.actor_user_id ? row.actor_user_id : null;
  const actorPseudonym =
    !actorUserId && row.actor_user_id
      ? pseudonymizeActor(row.actor_user_id)
      : row.actor_pseudonym || null;

  return {
    id: row.id,
    occurred_at: row.occurred_at,
    action: row.action,
    resource_type: row.resource_type,
    resource_id: row.resource_id,
    actor_user_id: actorUserId,
    actor_pseudonym: actorPseudonym,
    metadata: safeAuditMetadata(row.metadata),
  };
}

function bundlePresetsResponse() {
  return Object.entries(PERMISSION_BUNDLE_KEYS).map(([name, permissionKeys]) => ({
    name,
    permission_keys: [...permissionKeys],
  }));
}

async function loadActiveOverrides(pool, organizationId, userId) {
  const { rows } = await pool.query(
    `SELECT permission_key, source, granted_at
     FROM organization_permissions
     WHERE organization_id = $1
       AND user_id = $2
       AND revoked_at IS NULL
     ORDER BY permission_key`,
    [organizationId, userId],
  );
  return rows.map((row) => ({
    permission_key: row.permission_key,
    source: row.source,
    granted_at: row.granted_at,
  }));
}

export function registerPermissionsRoutes(router, pool) {
  router.get('/:orgId/permissions/me', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;

    try {
      const role = await loadMembershipRole(pool, orgId, userId);
      if (!role || role.startsWith('pending_')) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const overrideKeys = await loadActivePermissionKeys(pool, orgId, userId);
      const overrides = await loadActiveOverrides(pool, orgId, userId);
      res.json({
        role,
        effective_permissions: permissionKeysForRole(role, overrideKeys),
        overrides,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/permission-bundles', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }
      res.json({ presets: bundlePresetsResponse() });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/audit-events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }

      const { rows } = await pool.query(
        `SELECT id, occurred_at, action, resource_type, resource_id,
                actor_user_id, actor_pseudonym, metadata, retention_tier
         FROM audit_events
         WHERE org_id = $1
         ORDER BY occurred_at DESC
         LIMIT $2`,
        [orgId, AUDIT_EVENT_LIMIT],
      );
      res.json(rows.map(auditEventToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/members/:targetUserId/permissions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, targetUserId } = req.params;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }

      const role = await loadMembershipRole(pool, orgId, targetUserId);
      if (!role || role.startsWith('pending_')) {
        return res.status(404).json({ error: 'Member not found' });
      }

      const overrideKeys = await loadActivePermissionKeys(pool, orgId, targetUserId);
      const overrides = await loadActiveOverrides(pool, orgId, targetUserId);
      res.json({
        role,
        effective_permissions: permissionKeysForRole(role, overrideKeys),
        overrides,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/permissions/batch', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;
    const changes = req.body?.changes;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }
      if (!Array.isArray(changes) || changes.length === 0) {
        return res.status(400).json({ error: 'Invalid permission batch changes' });
      }

      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        const appliedCount = await applyPermissionBatch(client, {
          organizationId: orgId,
          changes,
          grantedBy: userId,
          req,
        });
        await client.query('COMMIT');
        res.json({ applied_count: appliedCount, change_count: changes.length });
      } catch (err) {
        await client.query('ROLLBACK');
        if (err.message?.startsWith('Invalid permission') || err.message?.startsWith('Member not found')) {
          return res.status(400).json({ error: err.message });
        }
        throw err;
      } finally {
        client.release();
      }
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/members/:targetUserId/permissions/bundle', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, targetUserId } = req.params;
    const preset = (req.body?.preset || '').trim();

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }
      if (!preset || !PERMISSION_BUNDLE_KEYS[preset]) {
        return res.status(400).json({ error: 'Invalid permission bundle preset' });
      }

      const role = await loadMembershipRole(pool, orgId, targetUserId);
      if (!role || role.startsWith('pending_')) {
        return res.status(404).json({ error: 'Member not found' });
      }

      const grantedCount = await applyBundlePreset(pool, {
        organizationId: orgId,
        userId: targetUserId,
        presetName: preset,
        grantedBy: userId,
        req,
      });

      const overrideKeys = await loadActivePermissionKeys(pool, orgId, targetUserId);
      res.json({
        preset,
        granted_count: grantedCount,
        effective_permissions: permissionKeysForRole(role, overrideKeys),
        overrides: await loadActiveOverrides(pool, orgId, targetUserId),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/members/:targetUserId/permissions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, targetUserId } = req.params;
    const permissionKey = (req.body?.permission_key || '').trim();

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }
      if (!permissionKey || !G0_PERMISSION_DEFAULTS[permissionKey]) {
        return res.status(400).json({ error: 'Invalid permission key' });
      }

      const role = await loadMembershipRole(pool, orgId, targetUserId);
      if (!role || role.startsWith('pending_')) {
        return res.status(404).json({ error: 'Member not found' });
      }

      await grantPermission(pool, {
        organizationId: orgId,
        userId: targetUserId,
        permissionKey,
        grantedBy: userId,
        source: 'individual',
        req,
      });

      const overrideKeys = await loadActivePermissionKeys(pool, orgId, targetUserId);
      res.json({
        permission_key: permissionKey,
        effective_permissions: permissionKeysForRole(role, overrideKeys),
        overrides: await loadActiveOverrides(pool, orgId, targetUserId),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/members/:targetUserId/permissions/:permissionKey', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, targetUserId, permissionKey } = req.params;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_permissions'))) {
        return;
      }
      if (!G0_PERMISSION_DEFAULTS[permissionKey]) {
        return res.status(400).json({ error: 'Invalid permission key' });
      }

      const role = await loadMembershipRole(pool, orgId, targetUserId);
      if (!role || role.startsWith('pending_')) {
        return res.status(404).json({ error: 'Member not found' });
      }

      const revoked = await revokePermission(pool, {
        organizationId: orgId,
        userId: targetUserId,
        permissionKey,
        revokedBy: userId,
        req,
      });
      if (!revoked) {
        return res.status(404).json({ error: 'Permission override not found' });
      }

      const overrideKeys = await loadActivePermissionKeys(pool, orgId, targetUserId);
      res.json({
        permission_key: permissionKey,
        effective_permissions: permissionKeysForRole(role, overrideKeys),
        overrides: await loadActiveOverrides(pool, orgId, targetUserId),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
