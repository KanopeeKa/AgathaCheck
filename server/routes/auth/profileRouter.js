import { errorDetails } from '../../config/security.js';
import { listFosterContactsForUser } from '../../lib/orgPeople.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { deletePostHogPerson } from '../../lib/posthogServer.js';
import { purgeAllPetFilesForUser } from '../../lib/petDataLifecycle.js';
import { revokeAllUserRefreshSessions } from '../../lib/refreshSessions.js';
import {
  buildUserDataExport,
  exportAuditMetadata,
} from '../../lib/gdprUserExport.js';
import {
  extractToken,
  getActiveOrgMembershipRole,
  isValidUuid,
  reconcilePinnedOrganizationId,
  userRowToMap,
  verifyToken,
} from './shared.js';

const PROFILE_FIELDS = ['first_name', 'last_name', 'category', 'bio', 'locale', 'photo_url'];

async function validatePinnedOrganizationUpdate(pool, userId, value) {
  if (value === null) {
    return { ok: true, pinnedOrganizationId: null };
  }
  if (value === undefined) {
    return { ok: true, skip: true };
  }
  if (typeof value !== 'string' || !isValidUuid(value)) {
    return { ok: false, status: 400, error: 'Invalid pinned_organization_id' };
  }
  const role = await getActiveOrgMembershipRole(pool, userId, value);
  if (!role) {
    return { ok: false, status: 403, error: 'Not an active member of this organization' };
  }
  return { ok: true, pinnedOrganizationId: value };
}

export function registerProfileRoutes(router, pool, { comparePassword }) {
  router.get('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const row = userResult.rows[0];
      const effectivePin = await reconcilePinnedOrganizationId(
        pool,
        payload.id,
        row.pinned_organization_id,
      );
      const user = userRowToMap({ ...row, pinned_organization_id: effectivePin });
      res.status(200).json(user);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  });

  router.get('/me/foster-contacts', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const contacts = await listFosterContactsForUser(pool, payload.id);
      res.status(200).json(contacts);
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token', ...errorDetails(err) });
    }
  });

  router.put('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const body = req.body;
      const updates = [];
      const values = [];
      let idx = 1;

      const pinValidation = await validatePinnedOrganizationUpdate(
        pool,
        payload.id,
        body.pinned_organization_id,
      );
      if (!pinValidation.ok) {
        return res.status(pinValidation.status).json({ error: pinValidation.error });
      }
      if (!pinValidation.skip) {
        updates.push(`pinned_organization_id = $${idx}`);
        values.push(pinValidation.pinnedOrganizationId);
        idx++;
      }

      for (const field of PROFILE_FIELDS) {
        if (body[field] !== undefined) {
          updates.push(`${field} = $${idx}`);
          values.push(body[field]);
          idx++;
        }
      }
      if (updates.length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }
      updates.push('updated_at = NOW()');
      values.push(payload.id);

      const result = await pool.query(
        `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
        values
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const changedFields = updates
        .filter((clause) => !clause.startsWith('updated_at'))
        .map((clause) => clause.split('=')[0].trim());
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'user.profile_updated',
        resourceType: 'user',
        resourceId: payload.id,
        metadata: { fields: changedFields },
        req,
      });
      const row = result.rows[0];
      const effectivePin = await reconcilePinnedOrganizationId(
        pool,
        payload.id,
        row.pinned_organization_id,
      );
      res.status(200).json(userRowToMap({ ...row, pinned_organization_id: effectivePin }));
    } catch (err) {
      return res.status(500).json({ error: 'Update failed', ...errorDetails(err) });
    }
  });

  router.post('/me/photo', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const photoUrl = `/uploads/photos/${payload.id}_${Date.now()}.jpg`;
      const result = await pool.query(
        'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [photoUrl, payload.id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'user.photo_updated',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      res.status(200).json(userRowToMap(result.rows[0]));
    } catch (err) {
      return res.status(500).json({ error: 'Photo upload failed', ...errorDetails(err) });
    }
  });

  router.delete('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const { password } = req.body;
      if (!password) {
        return res.status(400).json({ error: 'Password is required' });
      }
      const userResult = await pool.query('SELECT password_hash FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const valid = await comparePassword(password, userResult.rows[0].password_hash);
      if (!valid) {
        return res.status(400).json({ error: 'Password is incorrect' });
      }
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.account_deletion_requested',
        resourceType: 'user',
        resourceId: payload.id,
        req,
      });
      await revokeAllUserRefreshSessions(pool, payload.id);
      const purgeResult = await purgeAllPetFilesForUser(pool, payload.id);
      await deletePostHogPerson(payload.id);
      await pool.query('DELETE FROM users WHERE id = $1', [payload.id]);
      logAuditEventSafe(pool, {
        actorType: 'system',
        action: 'auth.account_deleted',
        resourceType: 'user',
        resourceId: payload.id,
        req,
        metadata: purgeResult,
      });
      res.status(200).json({ message: 'Account deleted successfully' });
    } catch (err) {
      return res.status(500).json({ error: 'Account deletion failed', ...errorDetails(err) });
    }
  });

  router.get('/me/export', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [payload.id]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const user = userRowToMap(userResult.rows[0]);
      const exportData = await buildUserDataExport(pool, payload.id);
      logAuditEventSafe(pool, {
        actorUserId: payload.id,
        action: 'auth.data_export',
        resourceType: 'user',
        resourceId: payload.id,
        metadata: exportAuditMetadata(exportData),
        req,
      });
      res.status(200).json({
        user,
        ...exportData,
        exported_at: new Date().toISOString(),
      });
    } catch (err) {
      return res.status(500).json({ error: 'Data export failed', ...errorDetails(err) });
    }
  });
}
