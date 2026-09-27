import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { todayCalendarIso } from '../../lib/calendarDate.js';
import { loadAwayPlanReadinessForAbsence } from '../../lib/care/awayPlan/index.js';
import { withOptionalTransaction } from '../../lib/db/withOptionalTransaction.js';
import {
  PLANNED_ABSENCE_PROVENANCE_USER_DECLARED,
  PLANNED_ABSENCE_STATUS_ACTIVE,
  PLANNED_ABSENCE_STATUS_CANCELLED,
  validateAbsenceDateWindow,
} from '../../lib/care/plannedAbsence.js';
import { loadUserTimezone } from '../../lib/people/absenceCarerInviteService.js';
import {
  applyGuestAccessWidenAfterPatch,
  evaluateGuestAccessWidenGate,
} from '../../lib/people/absenceGuestPatch.js';
import { revokeActiveGuestGrantsForAbsence } from '../../lib/people/absenceGuestGrants.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { registerAbsenceCarePlanRoutes } from './absenceCarePlanRouter.js';
import {
  absenceResponse,
  normalizeHandoverNoteInput,
} from './plannedAbsenceHandoverFields.js';
import { registerPlannedAbsenceHandoverRoutes } from './plannedAbsenceHandoverRoutes.js';
import { registerPlannedAbsenceCarerInviteRoutes } from './plannedAbsenceCarerInviteRoutes.js';
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

export function registerPlannedAbsenceRoutes(router, pool) {
  registerPlannedAbsenceCarerInviteRoutes(router, pool);

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
        petsByAbsence,
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
        window.ends_on,
      );
      const id = uuidv4();
      const provenance = body.provenance || PLANNED_ABSENCE_PROVENANCE_USER_DECLARED;
      const creatorTimezone = await loadUserTimezone(pool, userId);
      const row = await withOptionalTransaction(pool, async (client) => {
        const result = await client.query(
          `INSERT INTO planned_absences
             (id, user_id, starts_on, ends_on, provenance, source_ref, status, timezone)
           VALUES ($1, $2, $3::date, $4::date, $5, $6, $7, $8)
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
          ],
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

  registerAbsenceCarePlanRoutes(router, pool, {
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
      const originalPetIds = petRows.map((row) => row.pet_id);
      let petIds = [...originalPetIds];
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
        body.handover_note ?? body.handoverNote,
      );

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
        return res.status(widenGate.status).json(widenGate.payload);
      }

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
        [PLANNED_ABSENCE_STATUS_CANCELLED, req.params.id, userId],
      );
      if (result.rows.length === 0) {
        const row = await loadAbsenceForUser(pool, req.params.id, userId);
        if (!row) return res.status(404).json({ error: 'Not found' });
        return res.status(400).json({ error: 'Absence is already cancelled' });
      }
      await revokeActiveGuestGrantsForAbsence(pool, req.params.id);
      const petRows = await loadAbsencePets(pool, req.params.id);
      res.json(absenceResponse(result.rows[0], petRows));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
