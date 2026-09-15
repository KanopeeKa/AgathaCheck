import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { dateToIsoDate, todayCalendarIso } from '../../lib/calendarDate.js';
import { withOptionalTransaction } from '../../lib/db/withOptionalTransaction.js';
import {
  absenceToMap,
  dateRangesOverlap,
  PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
  validateAbsenceDateWindow,
  validateCarerInput,
} from '../../lib/care/plannedAbsence.js';
import { COLLABORATOR_ROLES, userCanManagePet } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

const COLLABORATOR_ROLES_SQL = COLLABORATOR_ROLES.map((role) => `'${role}'`).join(', ');

async function loadAbsencePets(pool, absenceId) {
  const result = await pool.query(
    `SELECT pet_id, carer_kind, carer_user_id, carer_name, carer_note
     FROM planned_absence_pets
     WHERE planned_absence_id = $1
     ORDER BY pet_id`,
    [absenceId]
  );
  return result.rows;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string[]} absenceIds
 * @returns {Promise<Map<string, object[]>>}
 */
async function loadPetsByAbsenceIds(pool, absenceIds) {
  const map = new Map();
  if (!absenceIds.length) return map;
  const result = await pool.query(
    `SELECT planned_absence_id, pet_id, carer_kind, carer_user_id, carer_name, carer_note
     FROM planned_absence_pets
     WHERE planned_absence_id = ANY($1::uuid[])
     ORDER BY pet_id`,
    [absenceIds]
  );
  for (const row of result.rows) {
    const list = map.get(row.planned_absence_id) || [];
    list.push(row);
    map.set(row.planned_absence_id, list);
  }
  return map;
}

async function loadAbsenceForUser(pool, absenceId, userId) {
  const result = await pool.query(
    'SELECT * FROM planned_absences WHERE id = $1 AND user_id = $2',
    [absenceId, userId]
  );
  return result.rows[0] || null;
}

async function assertManageablePets(pool, userId, petIds) {
  if (!Array.isArray(petIds) || petIds.length === 0) {
    return { ok: false, status: 400, error: 'At least one pet_id is required' };
  }
  const unique = [...new Set(petIds)];
  for (const petId of unique) {
    if (!(await userCanManagePet(pool, petId, userId))) {
      return { ok: false, status: 403, error: 'Forbidden' };
    }
  }
  return { ok: true, petIds: unique };
}

async function isCarerCandidate(pool, petId, carerUserId) {
  const result = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${COLLABORATOR_ROLES_SQL})
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, carerUserId]
  );
  return result.rows.length > 0;
}

/**
 * Non-blocking overlap warnings for same pet on other active absences.
 */
async function findOverlapWarnings(pool, userId, petIds, startsOn, endsOn, excludeAbsenceId = null) {
  const todayIso = todayCalendarIso();
  const result = await pool.query(
    `SELECT pa.id, pa.starts_on, pa.ends_on, pap.pet_id
     FROM planned_absences pa
     INNER JOIN planned_absence_pets pap ON pap.planned_absence_id = pa.id
     WHERE pa.user_id = $1
       AND pa.status != $2
       AND pa.ends_on >= $3::date
       AND pap.pet_id = ANY($4::uuid[])`,
    [userId, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso, petIds]
  );
  const warnings = [];
  for (const row of result.rows) {
    if (excludeAbsenceId && row.id === excludeAbsenceId) continue;
    const otherStart = dateToIsoDate(row.starts_on);
    const otherEnd = dateToIsoDate(row.ends_on);
    if (!otherStart || !otherEnd) continue;
    if (!dateRangesOverlap(startsOn, endsOn, otherStart, otherEnd)) continue;
    warnings.push({
      pet_id: row.pet_id,
      conflicting_absence_id: row.id,
      conflicting_starts_on: otherStart,
      conflicting_ends_on: otherEnd,
    });
  }
  return warnings;
}

async function replaceAbsencePets(pool, absenceId, petIds) {
  await pool.query(
    `DELETE FROM planned_absence_pets
     WHERE planned_absence_id = $1
       AND NOT (pet_id = ANY($2::uuid[]))`,
    [absenceId, petIds]
  );
  if (petIds.length === 0) return;
  await pool.query(
    `INSERT INTO planned_absence_pets (planned_absence_id, pet_id)
     SELECT $1, unnest($2::uuid[])
     ON CONFLICT (planned_absence_id, pet_id) DO NOTHING`,
    [absenceId, petIds]
  );
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} absenceId
 * @param {object[]} petCarersInput
 * @param {string[]} allowedPetIds
 */
async function updateAbsenceCarers(pool, absenceId, petCarersInput, allowedPetIds) {
  if (!Array.isArray(petCarersInput)) {
    return { ok: false, status: 400, error: 'pet_carers must be an array' };
  }
  const allowed = new Set(allowedPetIds);
  for (const item of petCarersInput) {
    const petId = item.pet_id || item.petId;
    if (!petId) {
      return { ok: false, status: 400, error: 'Each pet_carer entry requires pet_id' };
    }
    if (!allowed.has(petId)) {
      return { ok: false, status: 400, error: 'pet_id is not on this absence' };
    }
    const validated = validateCarerInput(item);
    if (!validated.ok) {
      return { ok: false, status: 400, error: validated.error };
    }
    if (validated.carer_kind === 'shared_user') {
      if (!(await isCarerCandidate(pool, petId, validated.carer_user_id))) {
        return { ok: false, status: 403, error: 'Forbidden' };
      }
    }
    await pool.query(
      `UPDATE planned_absence_pets
       SET carer_kind = $1,
           carer_user_id = $2,
           carer_name = $3,
           carer_note = $4
       WHERE planned_absence_id = $5 AND pet_id = $6`,
      [
        validated.carer_kind,
        validated.carer_user_id,
        validated.carer_name,
        validated.carer_note,
        absenceId,
        petId,
      ]
    );
  }
  return { ok: true };
}

export function registerPlannedAbsenceRoutes(router, pool) {
  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const todayIso = todayCalendarIso();
      const result = await pool.query(
        `SELECT * FROM planned_absences
         WHERE user_id = $1
           AND status != $2
           AND ends_on >= $3::date
         ORDER BY starts_on ASC`,
        [userId, PLANNED_ABSENCE_STATUS_CANCELLED, todayIso]
      );
      const absenceIds = result.rows.map((row) => row.id);
      const petsByAbsence = await loadPetsByAbsenceIds(pool, absenceIds);
      const items = result.rows.map((row) => absenceToMap(
        row,
        petsByAbsence.get(row.id) || []
      ));
      res.json(items);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const body = req.body || {};
    const window = validateAbsenceDateWindow(body.starts_on || body.startsOn, body.ends_on || body.endsOn);
    if (!window.ok) return res.status(400).json({ error: window.error });

    const petsCheck = await assertManageablePets(pool, userId, body.pet_ids || body.petIds);
    if (!petsCheck.ok) return res.status(petsCheck.status).json({ error: petsCheck.error });

    try {
      const overlapWarnings = await findOverlapWarnings(
        pool,
        userId,
        petsCheck.petIds,
        window.starts_on,
        window.ends_on
      );
      const id = uuidv4();
      const provenance = body.provenance || PLANNED_ABSENCE_PROVENANCE_USER_DECLARED;
      const row = await withOptionalTransaction(pool, async (client) => {
        const result = await client.query(
          `INSERT INTO planned_absences
             (id, user_id, starts_on, ends_on, provenance, source_ref, status)
           VALUES ($1, $2, $3::date, $4::date, $5, $6, $7)
           RETURNING *`,
          [
            id,
            userId,
            window.starts_on,
            window.ends_on,
            provenance,
            body.source_ref || body.sourceRef || null,
            PLANNED_ABSENCE_STATUS_ACTIVE,
          ]
        );
        await replaceAbsencePets(client, id, petsCheck.petIds);
        return result.rows[0];
      });
      const petRows = petsCheck.petIds.map((petId) => ({ pet_id: petId }));
      res.status(201).json({
        absence: absenceToMap(row, petRows),
        overlap_warnings: overlapWarnings,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await loadAbsenceForUser(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Not found' });
      const petRows = await loadAbsencePets(pool, row.id);
      res.json(absenceToMap(row, petRows));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const body = req.body || {};
    try {
      const existing = await loadAbsenceForUser(pool, req.params.id, userId);
      if (!existing) return res.status(404).json({ error: 'Not found' });
      if (existing.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
        return res.status(400).json({ error: 'Cannot edit a cancelled absence' });
      }

      const startsOn = body.starts_on || body.startsOn || existing.starts_on;
      const endsOn = body.ends_on || body.endsOn || existing.ends_on;
      const window = validateAbsenceDateWindow(startsOn, endsOn);
      if (!window.ok) return res.status(400).json({ error: window.error });

      let petRows = await loadAbsencePets(pool, existing.id);
      let petIds = petRows.map((row) => row.pet_id);
      if (body.pet_ids != null || body.petIds != null) {
        const petsCheck = await assertManageablePets(pool, userId, body.pet_ids || body.petIds);
        if (!petsCheck.ok) return res.status(petsCheck.status).json({ error: petsCheck.error });
        petIds = petsCheck.petIds;
        petRows = petIds.map((petId) => {
          const existingRow = petRows.find((row) => row.pet_id === petId);
          return existingRow || { pet_id: petId };
        });
      }

      const petCarersInput = body.pet_carers ?? body.petCarers ?? null;

      const overlapWarnings = await findOverlapWarnings(
        pool,
        userId,
        petIds,
        window.starts_on,
        window.ends_on,
        existing.id
      );

      const updated = await withOptionalTransaction(pool, async (client) => {
        if (petCarersInput != null) {
          const carerResult = await updateAbsenceCarers(client, existing.id, petCarersInput, petIds);
          if (!carerResult.ok) {
            throw Object.assign(new Error(carerResult.error), { status: carerResult.status });
          }
        }
        const result = await client.query(
          `UPDATE planned_absences
           SET starts_on = $1::date, ends_on = $2::date, updated_at = NOW()
           WHERE id = $3 AND user_id = $4
           RETURNING *`,
          [window.starts_on, window.ends_on, existing.id, userId]
        );
        await replaceAbsencePets(client, existing.id, petIds);
        return result.rows[0];
      });
      petRows = await loadAbsencePets(pool, existing.id);
      res.json({
        absence: absenceToMap(updated, petRows),
        overlap_warnings: overlapWarnings,
      });
    } catch (err) {
      if (err.status) {
        return res.status(err.status).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/cancel', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `UPDATE planned_absences
         SET status = $1, cancelled_at = NOW(), updated_at = NOW()
         WHERE id = $2 AND user_id = $3 AND status != $1
         RETURNING *`,
        [PLANNED_ABSENCE_STATUS_CANCELLED, req.params.id, userId]
      );
      if (result.rows.length === 0) {
        const row = await loadAbsenceForUser(pool, req.params.id, userId);
        if (!row) return res.status(404).json({ error: 'Not found' });
        return res.status(400).json({ error: 'Absence is already cancelled' });
      }
      const petRows = await loadAbsencePets(pool, req.params.id);
      res.json(absenceToMap(result.rows[0], petRows));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
