import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { loadAwayPlanProjection } from '../../lib/care/awayPlan/index.js';
import { buildCareReviewQueue } from '../../lib/care/awayPlan/reviewQueue.js';
import { petHasCarer } from '../../lib/care/awayPlan/readiness.js';
import {
  applyReviewQueueToCoverage,
  evaluateCarePeriodCoverageWithResolutions,
} from '../../lib/care/absence/absenceCoverage.js';
import { loadResolutionsByEntryIds } from '../../lib/care/absence/resolutionRepository.js';
import { evaluateCarePeriodCoverage } from '../../lib/care/carePeriodCoverage.js';
import { resolvePlannedAbsenceTodayIso, validateAbsenceDateWindow } from '../../lib/care/plannedAbsence.js';
import { loadPetHomeTimezone, wallClockInTimeZone } from '../../lib/petHomeTimezone.js';
import { userCanManagePet } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

export function registerCarePeriodCoverageRoutes(router, pool) {
  router.get('/:petId/care-period-coverage', asyncHandler(async (req, res) => {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { petId } = req.params;
      const {
        starts_on: startsOn,
        ends_on: endsOn,
        planned_absence_id: plannedAbsenceId,
      } = req.query;

      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const declarerTodayIso = await resolvePlannedAbsenceTodayIso(pool, userId);
      const window = validateAbsenceDateWindow(startsOn, endsOn, declarerTodayIso);
      if (!window.ok) {
        return res.status(400).json({ error: window.error });
      }

      const petTimeZone = await loadPetHomeTimezone(pool, petId);
      const careTodayIso = wallClockInTimeZone(petTimeZone).todayIso;
      const projection = await loadAwayPlanProjection(
        pool,
        petId,
        window.starts_on,
        window.ends_on,
        careTodayIso
      );

      let coverage = evaluateCarePeriodCoverage(projection);
      let reviewQueue = [];

      if (plannedAbsenceId) {
        const petRow = await pool.query(
          `SELECT *
           FROM planned_absence_pets
           WHERE planned_absence_id = $1 AND pet_id = $2`,
          [plannedAbsenceId, petId]
        );
        if (petRow.rows.length === 0) {
          return res.status(404).json({ error: 'Planned absence not found for pet' });
        }
        const entryIds = (projection.planned_care_items || []).map((row) => row.health_entry_id);
        const resolutionsByEntry = await loadResolutionsByEntryIds(
          pool,
          plannedAbsenceId,
          entryIds
        );
        reviewQueue = buildCareReviewQueue(
          projection.planned_care_items || [],
          projection.items || [],
          resolutionsByEntry,
          { startsOn: window.starts_on, endsOn: window.ends_on },
          { petHasCarer: petHasCarer(petRow.rows[0]) }
        );
        coverage = applyReviewQueueToCoverage(
          evaluateCarePeriodCoverageWithResolutions(
            projection,
            projection.planned_care_items || [],
            resolutionsByEntry,
            { startsOn: window.starts_on, endsOn: window.ends_on }
          ),
          reviewQueue
        );
      }

      return res.json({
        ...projection,
        coverage,
        review_queue: reviewQueue,
      });
    } catch (err) {
      throw err;
    }
  }));
}
