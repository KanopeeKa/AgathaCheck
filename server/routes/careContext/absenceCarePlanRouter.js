import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { loadAbsenceCarePlan } from '../../lib/care/planner/index.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 * @param {{
 *   loadAbsenceForViewer: (pool: import('pg').Pool, absenceId: string, userId: string) => Promise<object|null>,
 *   loadAbsencePets: (pool: import('pg').Pool, absenceId: string) => Promise<object[]>,
 * }} deps
 */
export function registerAbsenceCarePlanRoutes(router, pool, deps) {
  router.get('/:id/care-plan', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const viewed = await deps.loadAbsenceForViewer(pool, req.params.id, userId);
      if (!viewed) return res.status(404).json({ error: 'Not found' });
      const plan = await loadAbsenceCarePlan(pool, viewed.row, viewed.petRows);
      res.json(plan);
    } catch (err) {
      throw err;
    }
  }));
}
