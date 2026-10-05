import fs from 'fs';
import path from 'path';

import { errorDetails } from '../../config/security.js';
import {
  acceptAccountErasure,
  buildIdempotentErasureResponse,
  findErasureOperationForUser,
  getErasureStatus,
} from '../../lib/account/accountErasureService.js';
import { listFosterContactsForUser } from '../../lib/orgPeople.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { listHouseholdDependentOwnedPets } from '../../lib/households/accountDeletionGuard.js';
import { normalizeTimezoneInput } from '../../lib/timezone.js';
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

const PROFILE_FIELDS = [
  'first_name',
  'last_name',
  'category',
  'bio',
  'locale',
  'photo_url',
  'timezone',
  'weight_unit',
];
const WEIGHT_UNITS = new Set(['kg', 'lb']);

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

async function applyProfileUpdate(pool, userId, body, req) {
  const updates = [];
  const values = [];
  let idx = 1;

  const pinValidation = await validatePinnedOrganizationUpdate(
    pool,
    userId,
    body.pinned_organization_id,
  );
  if (!pinValidation.ok) {
    return pinValidation;
  }
  if (!pinValidation.skip) {
    updates.push(`pinned_organization_id = $${idx}`);
    values.push(pinValidation.pinnedOrganizationId);
    idx++;
  }

  for (const field of PROFILE_FIELDS) {
    if (body[field] !== undefined) {
      if (field === 'timezone') {
        const tz = normalizeTimezoneInput(body[field]);
        if (!tz) {
          return { ok: false, status: 400, error: 'Invalid timezone' };
        }
        updates.push(`${field} = $${idx}`);
        values.push(tz);
        idx++;
        continue;
      }
      if (field === 'weight_unit') {
        const unit = String(body[field] || '').trim().toLowerCase();
        if (!WEIGHT_UNITS.has(unit)) {
          return { ok: false, status: 400, error: 'weight_unit must be kg or lb' };
        }
        updates.push(`${field} = $${idx}`);
        values.push(unit);
        idx++;
        continue;
      }
      updates.push(`${field} = $${idx}`);
      values.push(body[field]);
      idx++;
    }
  }
  if (updates.length === 0) {
    return { ok: false, status: 400, error: 'No fields to update' };
  }
  updates.push('updated_at = NOW()');
  values.push(userId);

  const result = await pool.query(
    `UPDATE users SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
    values,
  );
  if (result.rows.length === 0) {
    return { ok: false, status: 404, error: 'User not found' };
  }
  const changedFields = updates
    .filter((clause) => !clause.startsWith('updated_at'))
    .map((clause) => clause.split('=')[0].trim());
  logAuditEventSafe(pool, {
    actorUserId: userId,
    action: 'user.profile_updated',
    resourceType: 'user',
    resourceId: userId,
    metadata: { fields: changedFields },
    req,
  });
  const row = result.rows[0];
  const effectivePin = await reconcilePinnedOrganizationId(
    pool,
    userId,
    row.pinned_organization_id,
  );
  return { ok: true, user: userRowToMap({ ...row, pinned_organization_id: effectivePin }) };
}

function uploadsPhotosDir() {
  const dir = path.resolve(process.cwd(), 'uploads', 'photos');
  fs.mkdirSync(dir, { recursive: true });
  return dir;
}

export function registerProfileRoutes(router, pool, { comparePassword, authLimiter }) {
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
      const result = await applyProfileUpdate(pool, payload.id, req.body || {}, req);
      if (!result.ok) {
        return res.status(result.status).json({ error: result.error });
      }
      res.status(200).json(result.user);
    } catch (err) {
      return res.status(500).json({ error: 'Update failed', ...errorDetails(err) });
    }
  });

  router.patch('/me', async (req, res) => {
    const token = extractToken(req);
    if (!token) {
      return res.status(401).json({ error: 'Missing or invalid Authorization header' });
    }
    try {
      const payload = verifyToken(token);
      const result = await applyProfileUpdate(pool, payload.id, req.body || {}, req);
      if (!result.ok) {
        return res.status(result.status).json({ error: result.error });
      }
      res.status(200).json(result.user);
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
      const relativePath = photoUrl.replace(/^\/uploads\//, '');
      const filePath = path.join(uploadsPhotosDir(), path.basename(relativePath));
      fs.writeFileSync(filePath, '');
      let result;
      try {
        result = await pool.query(
          'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
          [photoUrl, payload.id],
        );
        if (result.rows.length === 0) {
          try {
            fs.unlinkSync(filePath);
          } catch {
            // best-effort compensation
          }
          return res.status(404).json({ error: 'User not found' });
        }
      } catch (err) {
        try {
          fs.unlinkSync(filePath);
        } catch {
          // best-effort compensation
        }
        throw err;
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
      const { password, confirm_household_pets, confirmHouseholdPets } = req.body;
      if (!password) {
        return res.status(400).json({ error: 'Password is required' });
      }
      const dependents = await listHouseholdDependentOwnedPets(pool, payload.id);
      const confirmed = confirm_household_pets === true || confirmHouseholdPets === true;
      if (dependents.length > 0 && !confirmed) {
        return res.status(409).json({
          error: 'Account owns pets shared in a household with other members',
          code: 'household_pets_require_confirmation',
          pets: dependents.map((p) => ({
            id: p.id,
            name: p.name,
            household_id: p.household_id,
            household_name: p.household_name,
          })),
        });
      }
      const userResult = await pool.query(
        'SELECT password_hash, email FROM users WHERE id = $1',
        [payload.id],
      );
      if (userResult.rows.length === 0) {
        const existing = await findErasureOperationForUser(pool, payload.id);
        if (existing) {
          return res.status(202).json(buildIdempotentErasureResponse(existing));
        }
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
      const outcome = await acceptAccountErasure(pool, {
        userId: payload.id,
        userEmail: userResult.rows[0].email,
        req,
      });
      res.status(202).json(outcome);
    } catch (err) {
      return res.status(500).json({ error: 'Account deletion failed', ...errorDetails(err) });
    }
  });

  router.get('/erasure/:operationId', authLimiter, async (req, res) => {
    const statusToken = req.headers['x-erasure-status-token'];
    if (!statusToken || typeof statusToken !== 'string') {
      return res.status(404).json({ error: 'Not found' });
    }
    try {
      const result = await getErasureStatus(pool, req.params.operationId, statusToken);
      if (!result.ok) {
        return res.status(404).json({ error: 'Not found' });
      }
      res.status(200).json(result.body);
    } catch (err) {
      return res.status(500).json({ error: 'Erasure status failed', ...errorDetails(err) });
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
