import { publicError } from '../../config/security.js';
import { loadHealthEntryAbsenceContext } from '../../lib/care/absence/loadHealthEntryAbsenceContext.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { extractUserId } from './shared.js';

export function registerAbsenceContextRoutes(router, pool) {
  router.get('/:id/absence-context', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entryResult = await pool.query(
        'SELECT * FROM health_entries WHERE id = $1',
        [req.params.id]
      );
      const entry = entryResult.rows[0];
      if (!entry) return res.status(404).json({ error: 'Not found' });
      if (!(await userCanManageHealthEntry(pool, entry.id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const context = await loadHealthEntryAbsenceContext(pool, entry, userId);
      res.json(context);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
