import fs from 'fs';
import path from 'path';

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
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import {
  ForbiddenError,
  NotFoundError,
  ValidationError,
} from '../../lib/http/errors.js';
import { createRequireAuth, requireAuth } from '../../lib/requireAuth.js';

const requireAuthUpdate = createRequireAuth({ invalidTokenAsServerError: 'Update failed' });
const requireAuthPhoto = createRequireAuth({ invalidTokenAsServerError: 'Photo upload failed' });
const requireAuthExport = createRequireAuth({ invalidTokenAsServerError: 'Data export failed' });
const requireAuthDelete = createRequireAuth({ invalidTokenAsServerError: 'Account deletion failed' });
import {
  getActiveOrgMembershipRole,
  isValidUuid,
  reconcilePinnedOrganizationId,
  userRowToMap,
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

function throwProfileUpdateFailure(result) {
  if (result.status === 403) {
    throw new ForbiddenError(result.error);
  }
  if (result.status === 404) {
    throw new NotFoundError(result.error);
  }
  throw new ValidationError(result.error);
}

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
  router.get(
    '/me',
    requireAuth,
    asyncHandler(async (req, res) => {
      const userId = req.principal.id;
      const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
      if (userResult.rows.length === 0) {
        throw new NotFoundError('User not found');
      }
      const row = userResult.rows[0];
      const effectivePin = await reconcilePinnedOrganizationId(
        pool,
        userId,
        row.pinned_organization_id,
      );
      const user = userRowToMap({ ...row, pinned_organization_id: effectivePin });
      res.status(200).json(user);
    }),
  );

  router.get(
    '/me/foster-contacts',
    requireAuth,
    asyncHandler(async (req, res) => {
      const contacts = await listFosterContactsForUser(pool, req.principal.id);
      res.status(200).json(contacts);
    }),
  );

  router.put(
    '/me',
    requireAuthUpdate,
    asyncHandler(
      async (req, res) => {
        const result = await applyProfileUpdate(pool, req.principal.id, req.body || {}, req);
        if (!result.ok) {
          throwProfileUpdateFailure(result);
        }
        res.status(200).json(result.user);
      },
      { prodMessage: 'Update failed' },
    ),
  );

  router.patch(
    '/me',
    requireAuthUpdate,
    asyncHandler(
      async (req, res) => {
        const result = await applyProfileUpdate(pool, req.principal.id, req.body || {}, req);
        if (!result.ok) {
          throwProfileUpdateFailure(result);
        }
        res.status(200).json(result.user);
      },
      { prodMessage: 'Update failed' },
    ),
  );

  router.post(
    '/me/photo',
    requireAuthPhoto,
    asyncHandler(
      async (req, res) => {
        const userId = req.principal.id;
        const photoUrl = `/uploads/photos/${userId}_${Date.now()}.jpg`;
        const relativePath = photoUrl.replace(/^\/uploads\//, '');
        const filePath = path.join(uploadsPhotosDir(), path.basename(relativePath));
        fs.writeFileSync(filePath, '');
        let result;
        try {
          result = await pool.query(
            'UPDATE users SET photo_url = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
            [photoUrl, userId],
          );
          if (result.rows.length === 0) {
            try {
              fs.unlinkSync(filePath);
            } catch {
              // best-effort compensation
            }
            throw new NotFoundError('User not found');
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
          actorUserId: userId,
          action: 'user.photo_updated',
          resourceType: 'user',
          resourceId: userId,
          req,
        });
        res.status(200).json(userRowToMap(result.rows[0]));
      },
      { prodMessage: 'Photo upload failed' },
    ),
  );

  router.delete(
    '/me',
    requireAuthDelete,
    asyncHandler(
      async (req, res) => {
        const userId = req.principal.id;
        const { password, confirm_household_pets, confirmHouseholdPets } = req.body;
        if (!password) {
          throw new ValidationError('Password is required');
        }
        const dependents = await listHouseholdDependentOwnedPets(pool, userId);
        const confirmed = confirm_household_pets === true || confirmHouseholdPets === true;
        if (dependents.length > 0 && !confirmed) {
          const err = new Error('household pets confirmation required');
          err.status = 409;
          err.body = {
            error: 'Account owns pets shared in a household with other members',
            code: 'household_pets_require_confirmation',
            pets: dependents.map((p) => ({
              id: p.id,
              name: p.name,
              household_id: p.household_id,
              household_name: p.household_name,
            })),
          };
          throw err;
        }
        const userResult = await pool.query(
          'SELECT password_hash, email FROM users WHERE id = $1',
          [userId],
        );
        if (userResult.rows.length === 0) {
          const existing = await findErasureOperationForUser(pool, userId);
          if (existing) {
            return res.status(202).json(buildIdempotentErasureResponse(existing));
          }
          throw new NotFoundError('User not found');
        }
        const valid = await comparePassword(password, userResult.rows[0].password_hash);
        if (!valid) {
          throw new ValidationError('Password is incorrect');
        }
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'auth.account_deletion_requested',
          resourceType: 'user',
          resourceId: userId,
          req,
        });
        const outcome = await acceptAccountErasure(pool, {
          userId,
          userEmail: userResult.rows[0].email,
          req,
        });
        res.status(202).json(outcome);
      },
      { prodMessage: 'Account deletion failed' },
    ),
  );

  router.get(
    '/erasure/:operationId',
    authLimiter,
    asyncHandler(
      async (req, res) => {
        const statusToken = req.headers['x-erasure-status-token'];
        if (!statusToken || typeof statusToken !== 'string') {
          throw new NotFoundError('Not found');
        }
        const result = await getErasureStatus(pool, req.params.operationId, statusToken);
        if (!result.ok) {
          throw new NotFoundError('Not found');
        }
        res.status(200).json(result.body);
      },
      { prodMessage: 'Erasure status failed' },
    ),
  );

  router.get(
    '/me/export',
    requireAuthExport,
    asyncHandler(
      async (req, res) => {
        const userId = req.principal.id;
        const userResult = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
        if (userResult.rows.length === 0) {
          throw new NotFoundError('User not found');
        }
        const user = userRowToMap(userResult.rows[0]);
        const exportData = await buildUserDataExport(pool, userId);
        logAuditEventSafe(pool, {
          actorUserId: userId,
          action: 'auth.data_export',
          resourceType: 'user',
          resourceId: userId,
          metadata: exportAuditMetadata(exportData),
          req,
        });
        res.status(200).json({
          user,
          ...exportData,
          exported_at: new Date().toISOString(),
        });
      },
      { prodMessage: 'Data export failed' },
    ),
  );
}
