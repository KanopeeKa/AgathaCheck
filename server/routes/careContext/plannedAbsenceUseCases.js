/**
 * Planned absence list/create/patch/cancel use cases for care-context routes.
 */

import { v4 as uuidv4 } from 'uuid';
import { todayCalendarIso } from '../../lib/calendarDate.js';
import { loadAwayPlanReadinessForAbsence } from '../../lib/care/awayPlan/index.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import {
  PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
  normalizeAbsenceTitleInput,
  validateAbsenceDateWindow,
} from '../../lib/care/plannedAbsence.js';
import { loadUserTimezone } from '../../lib/people/absenceCarerInviteService.js';
import {
  applyGuestAccessWidenAfterPatch,
  evaluateGuestAccessWidenGate,
} from '../../lib/people/absenceGuestPatch.js';
import { revokeActiveGuestGrantsForAbsence } from '../../lib/people/absenceGuestGrants.js';
import {
  absenceResponse,
  normalizeHandoverNoteInput,
} from './plannedAbsenceHandoverFields.js';
import {
  assertManageablePets,
  listAbsencesSql,
  loadAbsenceForUser,
  loadAbsencePets,
  loadPetsByAbsenceIds,
  parseListScope,
  replaceAbsencePets,
  updateAbsenceCarers,
} from './plannedAbsenceStore.js';
import {
  findOverlapWarnings,
  loadOverlapCandidatesForAbsences,
  overlapWarningsForAbsence,
} from './plannedAbsenceOverlap.js';

export async function listPlannedAbsences(pool, userId, scopeResult) {
  const todayIso = todayCalendarIso();
  const { sql, params } = listAbsencesSql(scopeResult.scope, todayIso);
  const result = await pool.query(sql, [userId, ...params]);
  const absenceIds = result.rows.map((row) => row.id);
  const petsByAbsence = await loadPetsByAbsenceIds(pool, absenceIds);
  const overlapCandidates = await loadOverlapCandidatesForAbsences(
    pool,
    userId,
    result.rows,
    petsByAbsence,
  );
  return result.rows.map((row) => {
    const petRows = petsByAbsence.get(row.id) || [];
    return {
      ...absenceResponse(row, petRows),
      overlap_warnings: overlapWarningsForAbsence(row, petRows, overlapCandidates),
    };
  });
}

export async function createPlannedAbsence(pool, userId, body) {
  const window = validateAbsenceDateWindow(body.starts_on || body.startsOn, body.ends_on || body.endsOn);
  if (!window.ok) return { status: 400, error: window.error };

  const petsCheck = await assertManageablePets(pool, userId, body.pet_ids || body.petIds);
  if (!petsCheck.ok) return { status: petsCheck.status, error: petsCheck.error };

  const titleResult = normalizeAbsenceTitleInput(body.title);
  if (!titleResult.ok) return { status: 400, error: titleResult.error };

  const overlapWarnings = await findOverlapWarnings(
    pool,
    userId,
    petsCheck.petIds,
    window.starts_on,
    window.ends_on,
  );
  const id = uuidv4();
  const provenance = body.provenance || PLANNED_ABSENCE_PROVENANCE_USER_DECLARED;
  const creatorTimezone = await loadUserTimezone(pool, userId);
  const row = await withTransaction(pool, async (client) => {
    const result = await client.query(
      `INSERT INTO planned_absences
         (id, user_id, starts_on, ends_on, provenance, source_ref, status, timezone, title)
       VALUES ($1, $2, $3::date, $4::date, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        id,
        userId,
        window.starts_on,
        window.ends_on,
        provenance,
        body.source_ref || body.sourceRef || null,
        PLANNED_ABSENCE_STATUS_ACTIVE,
        creatorTimezone,
        titleResult.title ?? null,
      ],
    );
    await replaceAbsencePets(client, id, petsCheck.petIds);
    return result.rows[0];
  });
  const petRows = petsCheck.petIds.map((petId) => ({ pet_id: petId }));
  return {
    status: 201,
    body: {
      absence: absenceResponse(row, petRows),
      overlap_warnings: overlapWarnings,
    },
  };
}

export async function getPlannedAbsenceDetail(pool, userId, absenceId) {
  const row = await loadAbsenceForUser(pool, absenceId, userId);
  if (!row) return { status: 404, error: 'Not found' };
  const petRows = await loadAbsencePets(pool, row.id);
  return { absence: absenceResponse(row, petRows) };
}

export async function getPlannedAbsenceReadiness(pool, userId, absenceId) {
  const row = await loadAbsenceForUser(pool, absenceId, userId);
  if (!row) return { status: 404, error: 'Not found' };
  const petRows = await loadAbsencePets(pool, row.id);
  const readiness = await loadAwayPlanReadinessForAbsence(pool, row, petRows);
  return { readiness };
}

export async function patchPlannedAbsence(pool, userId, absenceId, body) {
  const existing = await loadAbsenceForUser(pool, absenceId, userId);
  if (!existing) return { status: 404, error: 'Not found' };
  if (existing.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 400, error: 'Cannot edit a cancelled absence' };
  }

  const startsOn = body.starts_on || body.startsOn || existing.starts_on;
  const endsOn = body.ends_on || body.endsOn || existing.ends_on;
  const window = validateAbsenceDateWindow(startsOn, endsOn);
  if (!window.ok) return { status: 400, error: window.error };

  let petRows = await loadAbsencePets(pool, existing.id);
  const originalPetIds = petRows.map((row) => row.pet_id);
  let petIds = [...originalPetIds];
  if (body.pet_ids != null || body.petIds != null) {
    const petsCheck = await assertManageablePets(pool, userId, body.pet_ids || body.petIds);
    if (!petsCheck.ok) return { status: petsCheck.status, error: petsCheck.error };
    petIds = petsCheck.petIds;
    petRows = petIds.map((petId) => {
      const existingRow = petRows.find((row) => row.pet_id === petId);
      return existingRow || { pet_id: petId };
    });
  }

  const petCarersInput = body.pet_carers ?? body.petCarers ?? null;
  const handoverNote = normalizeHandoverNoteInput(body.handover_note ?? body.handoverNote);
  const titleResult = normalizeAbsenceTitleInput(body.title);
  if (!titleResult.ok) return { status: 400, error: titleResult.error };

  const overlapWarnings = await findOverlapWarnings(
    pool,
    userId,
    petIds,
    window.starts_on,
    window.ends_on,
    existing.id,
  );

  const widenGate = await evaluateGuestAccessWidenGate(pool, {
    existing,
    body,
    oldPetIds: originalPetIds,
    newPetIds: petIds,
    window,
  });
  if (!widenGate.ok) {
    return { status: widenGate.status, payload: widenGate.payload };
  }

  try {
    const updated = await withTransaction(pool, async (client) => {
      const setClauses = ['starts_on = $1::date', 'ends_on = $2::date', 'updated_at = NOW()'];
      const updateParams = [window.starts_on, window.ends_on];
      if (handoverNote !== undefined) {
        setClauses.push(`handover_note = $${updateParams.length + 1}`);
        updateParams.push(handoverNote);
      }
      if (titleResult.title !== undefined) {
        setClauses.push(`title = $${updateParams.length + 1}`);
        updateParams.push(titleResult.title);
      }
      updateParams.push(existing.id, userId);
      const result = await client.query(
        `UPDATE planned_absences
         SET ${setClauses.join(', ')}
         WHERE id = $${updateParams.length - 1} AND user_id = $${updateParams.length}
         RETURNING *`,
        updateParams,
      );
      await replaceAbsencePets(client, existing.id, petIds);
      if (petCarersInput != null) {
        const carerResult = await updateAbsenceCarers(
          client,
          existing.id,
          petCarersInput,
          petIds,
          userId,
        );
        if (!carerResult.ok) {
          throw Object.assign(new Error(carerResult.error), { status: carerResult.status });
        }
      }
      await applyGuestAccessWidenAfterPatch(client, {
        absenceId: existing.id,
        widen: widenGate.widen,
        confirmed: widenGate.confirmed,
        actorUserId: userId,
      });
      return result.rows[0];
    });
    petRows = await loadAbsencePets(pool, existing.id);
    return {
      body: {
        absence: absenceResponse(updated, petRows),
        overlap_warnings: overlapWarnings,
      },
    };
  } catch (err) {
    if (err.status) {
      return { status: err.status, error: err.message };
    }
    throw err;
  }
}

export async function cancelPlannedAbsence(pool, userId, absenceId) {
  const result = await pool.query(
    `UPDATE planned_absences
     SET status = $1, cancelled_at = NOW(), updated_at = NOW()
     WHERE id = $2 AND user_id = $3 AND status != $1
     RETURNING *`,
    [PLANNED_ABSENCE_STATUS_CANCELLED, absenceId, userId],
  );
  if (result.rows.length === 0) {
    const row = await loadAbsenceForUser(pool, absenceId, userId);
    if (!row) return { status: 404, error: 'Not found' };
    return { status: 400, error: 'Absence is already cancelled' };
  }
  await revokeActiveGuestGrantsForAbsence(pool, absenceId);
  const petRows = await loadAbsencePets(pool, absenceId);
  return { absence: absenceResponse(result.rows[0], petRows) };
}

export { parseListScope };
