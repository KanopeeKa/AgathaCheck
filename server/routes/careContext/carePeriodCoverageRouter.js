import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { loadAwayPlanProjection } from '../../lib/care/awayPlan/index.js';
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
      const { starts_on: startsOn, ends_on: endsOn } = req.query;
      const declarerTodayIso = await resolvePlannedAbsenceTodayIso(pool, userId);
      const window = validateAbsenceDateWindow(startsOn, endsOn, declarerTodayIso);
      if (!window.ok) {
        return res.status(400).json({ error: window.error });
      }

      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
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
      const coverage = evaluateCarePeriodCoverage(projection);

      return res.json({
        ...projection,
        coverage,
      });
    } catch (err) {
      throw err;
    }
  }));
}
