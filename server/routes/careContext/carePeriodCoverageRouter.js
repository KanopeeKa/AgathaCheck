import { publicError } from '../../config/security.js';
import { loadCarePeriodCoverage } from '../../lib/care/carePeriodCoverage.js';
import { validateAbsenceDateWindow } from '../../lib/care/plannedAbsence.js';
import { todayCalendarIso } from '../../lib/calendarDate.js';
import { userCanManagePet } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

export function registerCarePeriodCoverageRoutes(router, pool) {
  router.get('/:petId/care-period-coverage', async (req, res) => {
    try {
      const userId = extractUserId(req);
      if (!userId) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      const { petId } = req.params;
      const { starts_on: startsOn, ends_on: endsOn } = req.query;
      const window = validateAbsenceDateWindow(startsOn, endsOn, todayCalendarIso());
      if (!window.ok) {
        return res.status(400).json({ error: window.error });
      }

      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const payload = await loadCarePeriodCoverage(
        pool,
        petId,
        window.starts_on,
        window.ends_on,
        todayCalendarIso()
      );

      return res.json(payload);
    } catch (err) {
      return publicError(res, err, 'Failed to load care-period coverage');
    }
  });
}
