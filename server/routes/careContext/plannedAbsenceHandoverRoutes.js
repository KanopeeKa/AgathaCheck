import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { absenceResponse } from './plannedAbsenceHandoverFields.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 * @param {{
 *   loadAbsenceForUser: (pool: import('pg').Pool, absenceId: string, userId: string) => Promise<object|null>,
 *   loadAbsencePets: (pool: import('pg').Pool, absenceId: string) => Promise<object[]>,
 * }} deps
 */
export function registerPlannedAbsenceHandoverRoutes(router, pool, deps) {
  router.post('/:id/record-handover-download', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `UPDATE planned_absences
         SET last_handover_downloaded_at = NOW(), updated_at = NOW()
         WHERE id = $1 AND user_id = $2
         RETURNING *`,
        [req.params.id, userId]
      );
      if (result.rows.length === 0) {
        const row = await deps.loadAbsenceForUser(pool, req.params.id, userId);
        if (!row) return res.status(404).json({ error: 'Not found' });
        return res.status(400).json({ error: 'Could not record handover download' });
      }
      const petRows = await deps.loadAbsencePets(pool, req.params.id);
      res.json(absenceResponse(result.rows[0], petRows));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
