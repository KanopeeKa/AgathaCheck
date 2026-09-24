import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { loadAbsenceCarePlan } from '../../lib/care/planner/index.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 * @param {{
 *   loadAbsenceForUser: (pool: import('pg').Pool, absenceId: string, userId: string) => Promise<object|null>,
 *   loadAbsencePets: (pool: import('pg').Pool, absenceId: string) => Promise<object[]>,
 * }} deps
 */
export function registerAbsenceCarePlanRoutes(router, pool, deps) {
  router.get('/:id/care-plan', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await deps.loadAbsenceForUser(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Not found' });
      const petRows = await deps.loadAbsencePets(pool, row.id);
      const plan = await loadAbsenceCarePlan(pool, row, petRows);
      res.json(plan);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
