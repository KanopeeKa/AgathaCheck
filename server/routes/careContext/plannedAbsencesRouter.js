import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { todayCalendarIso } from '../../lib/calendarDate.js';
import {
  absenceToMap,
  dateRangesOverlap,
  PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
  validateAbsenceDateWindow,
} from '../../lib/care/plannedAbsence.js';
import { userCanManagePet } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

async function loadPetIds(pool, absenceId) {
  const result = await pool.query(
    'SELECT pet_id FROM planned_absence_pets WHERE planned_absence_id = $1 ORDER BY pet_id',
    [absenceId]
  );
  return result.rows.map((r) => r.pet_id);
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
    const otherStart = row.starts_on.toISOString?.().slice(0, 10)
      || String(row.starts_on).slice(0, 10);
    const otherEnd = row.ends_on.toISOString?.().slice(0, 10)
      || String(row.ends_on).slice(0, 10);
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
  await pool.query('DELETE FROM planned_absence_pets WHERE planned_absence_id = $1', [absenceId]);
  for (const petId of petIds) {
    await pool.query(
      'INSERT INTO planned_absence_pets (planned_absence_id, pet_id) VALUES ($1, $2)',
      [absenceId, petId]
    );
  }
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
      const items = [];
      for (const row of result.rows) {
        const petIds = await loadPetIds(pool, row.id);
        items.push(absenceToMap(row, petIds));
      }
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
      const result = await pool.query(
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
      await replaceAbsencePets(pool, id, petsCheck.petIds);
      res.status(201).json({
        absence: absenceToMap(result.rows[0], petsCheck.petIds),
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
      const petIds = await loadPetIds(pool, row.id);
      res.json(absenceToMap(row, petIds));
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

      let petIds = await loadPetIds(pool, existing.id);
      if (body.pet_ids != null || body.petIds != null) {
        const petsCheck = await assertManageablePets(pool, userId, body.pet_ids || body.petIds);
        if (!petsCheck.ok) return res.status(petsCheck.status).json({ error: petsCheck.error });
        petIds = petsCheck.petIds;
      }

      const overlapWarnings = await findOverlapWarnings(
        pool,
        userId,
        petIds,
        window.starts_on,
        window.ends_on,
        existing.id
      );

      const result = await pool.query(
        `UPDATE planned_absences
         SET starts_on = $1::date, ends_on = $2::date, updated_at = NOW()
         WHERE id = $3 AND user_id = $4
         RETURNING *`,
        [window.starts_on, window.ends_on, existing.id, userId]
      );
      await replaceAbsencePets(pool, existing.id, petIds);
      res.json({
        absence: absenceToMap(result.rows[0], petIds),
        overlap_warnings: overlapWarnings,
      });
    } catch (err) {
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
      const petIds = await loadPetIds(pool, req.params.id);
      res.json(absenceToMap(result.rows[0], petIds));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
