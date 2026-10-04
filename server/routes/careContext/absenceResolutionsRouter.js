import { publicError } from '../../config/security.js';
import { dateToIsoDate, todayCalendarIso } from '../../lib/calendarDate.js';
import { loadAwayPlanProjection } from '../../lib/care/awayPlan/index.js';
import { isCareItemAffectedByAbsence } from '../../lib/care/absence/affectedCareItem.js';
import { RESOLUTION_DECISION_MOVE_AFTER } from '../../lib/care/absence/constants.js';
import { buildReviewOccurrence } from '../../lib/care/absence/plannedDatesInTrip.js';
import { applyMoveAfterAbsenceReturn } from '../../lib/care/absence/postponeAfterAbsenceReturn.js';
import {
  listResolutionsForAbsence,
  upsertResolution,
} from '../../lib/care/absence/resolutionRepository.js';
import { PET_ACCESS_ROLES, userCanManageCare } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

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

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 * @param {{
 *   loadAbsenceForUser: Function,
 *   loadAbsencePets: Function,
 * }} deps
 */
export function registerAbsenceResolutionsRoutes(router, pool, deps) {
  router.get('/:id/resolutions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await deps.loadAbsenceForUser(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Not found' });
      const resolutions = await listResolutionsForAbsence(pool, row.id);
      res.json({ resolutions });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id/resolutions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const body = req.body || {};
    try {
      const absenceRow = await deps.loadAbsenceForUser(pool, req.params.id, userId);
      if (!absenceRow) return res.status(404).json({ error: 'Not found' });

      const petRows = await deps.loadAbsencePets(pool, absenceRow.id);
      const startsOn = dateToIsoDate(absenceRow.starts_on);
      const endsOn = dateToIsoDate(absenceRow.ends_on);
      const todayIso = todayCalendarIso();

      const rawItems = body.resolutions ?? (body.health_entry_id || body.healthEntryId ? [body] : null);
      if (!Array.isArray(rawItems) || rawItems.length === 0) {
        return res.status(400).json({ error: 'resolutions array or health_entry_id is required' });
      }

      const upserted = [];
      for (const item of rawItems) {
        const healthEntryId = item.health_entry_id || item.healthEntryId;
        if (!healthEntryId) {
          return res.status(400).json({ error: 'Each resolution requires health_entry_id' });
        }

        const entryResult = await pool.query(
          'SELECT id, pet_id FROM health_entries WHERE id = $1',
          [healthEntryId]
        );
        const entry = entryResult.rows[0];
        if (!entry) {
          return res.status(404).json({ error: 'Health entry not found' });
        }
        const onAbsence = petRows.some((petRow) => petRow.pet_id === entry.pet_id);
        if (!onAbsence) {
          return res.status(400).json({ error: 'Health entry pet is not on this absence' });
        }
        if (!(await userCanManageCare(pool, entry.pet_id, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }

        const lookedAfter = item.looked_after_by ?? item.lookedAfterBy;
        if (lookedAfter?.carer_kind === 'shared_user' || lookedAfter?.carerKind === 'shared_user') {
          const carerUserId = lookedAfter.carer_user_id || lookedAfter.carerUserId;
          if (carerUserId && !(await isCarerCandidate(pool, entry.pet_id, carerUserId))) {
            return res.status(403).json({ error: 'Forbidden' });
          }
        }

        const projection = await loadAwayPlanProjection(
          pool,
          entry.pet_id,
          startsOn,
          endsOn,
          todayIso
        );
        const plannedRow = (projection.planned_care_items || []).find(
          (row) => row.health_entry_id === healthEntryId
        );
        if (!plannedRow || !isCareItemAffectedByAbsence(plannedRow)) {
          return res.status(400).json({ error: 'Care item is not affected by this absence' });
        }

        const decision = item.decision;
        const recordOnly = item.record_only === true || item.recordOnly === true;
        if (decision === RESOLUTION_DECISION_MOVE_AFTER && !recordOnly) {
          const review = buildReviewOccurrence(plannedRow);
          const applied = await applyMoveAfterAbsenceReturn(pool, {
            entryId: healthEntryId,
            userId,
            req,
            absenceId: absenceRow.id,
            endsOn,
            occurrenceId: item.occurrence_id || item.occurrenceId || review?.occurrence_id || null,
          });
          if (!applied.ok) {
            const status = applied.status || 400;
            if (applied.body) {
              return res.status(status).json(applied.body);
            }
            return res.status(status).json({ error: applied.error || 'Could not postpone care' });
          }
        }

        const result = await upsertResolution(pool, absenceRow.id, healthEntryId, item, {
          startsOn,
          endsOn,
          projectionItems: projection.items,
        });
        if (!result.ok) {
          return res.status(400).json({ error: result.error });
        }
        upserted.push(result.resolution);
      }

      res.json({ resolutions: upserted });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
