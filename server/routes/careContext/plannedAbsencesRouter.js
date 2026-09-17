import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { todayCalendarIso } from '../../lib/calendarDate.js';
import { loadAwayPlanReadinessForAbsence } from '../../lib/care/awayPlan/index.js';
import { withOptionalTransaction } from '../../lib/db/withOptionalTransaction.js';
import {
  PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
  enrichSharedUserCarerNames,
  validateAbsenceDateWindow,
  validateCarerInput,
} from '../../lib/care/plannedAbsence.js';
import { PET_ACCESS_ROLES, userCanManageCare } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  absenceResponse,
  normalizeHandoverNoteInput,
} from './plannedAbsenceHandoverFields.js';
import { registerPlannedAbsenceHandoverRoutes } from './plannedAbsenceHandoverRoutes.js';
import {
  findOverlapWarnings,
  loadOverlapCandidatesForAbsences,
  overlapWarningsForAbsence,
} from './plannedAbsenceOverlap.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

async function loadAbsencePets(pool, absenceId) {
  const result = await pool.query(
    `SELECT pet_id, carer_kind, carer_user_id, carer_name, carer_note
     FROM planned_absence_pets
     WHERE planned_absence_id = $1
     ORDER BY pet_id`,
    [absenceId]
  );
  return enrichSharedUserCarerNames(pool, result.rows);
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
  if (map.size === 0) return map;
  for (const [absenceId, petRows] of map) {
    map.set(absenceId, await enrichSharedUserCarerNames(pool, petRows));
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
    if (!(await userCanManageCare(pool, petId, userId))) {
      return { ok: false, status: 403, error: 'Forbidden' };
    }
  }
  return { ok: true, petIds: unique };
}

async function isCarerCandidate(pool, petId, carerUserId) {
  const result = await pool.query(
    `SELECT 1 FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL})
       AND COALESCE(hidden, false) = false
     LIMIT 1`,
    [petId, carerUserId]
  );
  return result.rows.length > 0;
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

const LIST_SCOPES = new Set(['upcoming', 'past', 'all']);

/**
 * @param {import('express').Request} req
 * @returns {{ ok: true, scope: string } | { ok: false, error: string }}
 */
function parseListScope(req) {
  const raw = req.query.scope;
  const scope = raw == null || raw === '' ? 'upcoming' : String(raw).trim().toLowerCase();
  if (!LIST_SCOPES.has(scope)) {
    return { ok: false, error: 'scope must be upcoming, past, or all' };
  }
  return { ok: true, scope };
}

/**
 * @param {string} scope
 * @param {string} todayIso
 */
function listAbsencesSql(scope, todayIso) {
  const base = `SELECT * FROM planned_absences
     WHERE user_id = $1
       AND status != $2`;
  if (scope === 'upcoming') {
    return {
      sql: `${base}
         AND ends_on >= $3::date
         ORDER BY starts_on ASC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  if (scope === 'past') {
    return {
      sql: `${base}
         AND ends_on < $3::date
         ORDER BY starts_on DESC`,
      params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
    };
  }
  return {
    sql: `${base}
       ORDER BY (ends_on < $3::date)::int,
                CASE WHEN ends_on >= $3::date THEN starts_on END ASC NULLS LAST,
                CASE WHEN ends_on < $3::date THEN starts_on END DESC NULLS LAST`,
    params: [PLANNED_ABSENCE_STATUS_CANCELLED, todayIso],
  };
}

export function registerPlannedAbsenceRoutes(router, pool) {
  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const scopeResult = parseListScope(req);
    if (!scopeResult.ok) return res.status(400).json({ error: scopeResult.error });
    try {
      const todayIso = todayCalendarIso();
      const { sql, params } = listAbsencesSql(scopeResult.scope, todayIso);
      const result = await pool.query(sql, [userId, ...params]);
      const absenceIds = result.rows.map((row) => row.id);
      const petsByAbsence = await loadPetsByAbsenceIds(pool, absenceIds);
      const overlapCandidates = await loadOverlapCandidatesForAbsences(
        pool,
        userId,
        result.rows,
        petsByAbsence
      );
      const items = result.rows.map((row) => {
        const petRows = petsByAbsence.get(row.id) || [];
        return {
          ...absenceResponse(row, petRows),
          overlap_warnings: overlapWarningsForAbsence(row, petRows, overlapCandidates),
        };
      });
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
        absence: absenceResponse(row, petRows),
        overlap_warnings: overlapWarnings,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  registerPlannedAbsenceHandoverRoutes(router, pool, {
    loadAbsenceForUser,
    loadAbsencePets,
  });

  router.get('/:id/readiness', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await loadAbsenceForUser(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Not found' });
      const petRows = await loadAbsencePets(pool, row.id);
      const readiness = await loadAwayPlanReadinessForAbsence(pool, row, petRows);
      res.json(readiness);
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
      res.json(absenceResponse(row, petRows));
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
      const handoverNote = normalizeHandoverNoteInput(
        body.handover_note ?? body.handoverNote
      );

      const overlapWarnings = await findOverlapWarnings(
        pool,
        userId,
        petIds,
        window.starts_on,
        window.ends_on,
        existing.id
      );

      const updated = await withOptionalTransaction(pool, async (client) => {
        const setClauses = ['starts_on = $1::date', 'ends_on = $2::date', 'updated_at = NOW()'];
        const updateParams = [window.starts_on, window.ends_on];
        if (handoverNote !== undefined) {
          setClauses.push(`handover_note = $${updateParams.length + 1}`);
          updateParams.push(handoverNote);
        }
        updateParams.push(existing.id, userId);
        const result = await client.query(
          `UPDATE planned_absences
           SET ${setClauses.join(', ')}
           WHERE id = $${updateParams.length - 1} AND user_id = $${updateParams.length}
           RETURNING *`,
          updateParams
        );
        await replaceAbsencePets(client, existing.id, petIds);
        if (petCarersInput != null) {
          const carerResult = await updateAbsenceCarers(client, existing.id, petCarersInput, petIds);
          if (!carerResult.ok) {
            throw Object.assign(new Error(carerResult.error), { status: carerResult.status });
          }
        }
        return result.rows[0];
      });
      petRows = await loadAbsencePets(pool, existing.id);
      res.json({
        absence: absenceResponse(updated, petRows),
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
      res.json(absenceResponse(result.rows[0], petRows));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
