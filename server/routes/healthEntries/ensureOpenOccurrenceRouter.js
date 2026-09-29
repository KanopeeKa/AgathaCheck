import { runCareCommand } from '../../lib/care/occurrence/index.js';
import { occurrenceToMap } from '../../lib/occurrenceScheduling.js';
import { publicError } from '../../config/security.js';
import { extractUserId } from './shared.js';
import { loadEntry } from './occurrencesRouter.js';

/**
 * Compatibility (deleted in child F): every active planned item already has
 * an open occurrence (D-CSM-019), so this only runs the catch-up and returns
 * the current open occurrences.
 *
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 */
export function registerEnsureOpenOccurrenceRoutes(router, pool) {
  router.post('/:id/occurrences/ensure-open', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      if (entry.status === 'paused') {
        return res.status(400).json({ error: 'Care item is paused' });
      }
      const out = await runCareCommand(pool, { entryId: entry.id, userId, req }, async () => ({ event: null }));
      if (!out) return res.status(404).json({ error: 'Entry not found' });
      if (out.openOccurrences.length === 0) {
        return res.status(400).json({ error: 'No open date to materialise' });
      }
      const headDate = out.openOccurrences[0].scheduled_date;
      return res.json({
        occurrences: out.openOccurrences
          .filter((o) => o.scheduled_date === headDate)
          .map((o) => occurrenceToMap(o)),
        created: false,
        next_due_date: headDate,
        head_date: headDate,
      });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
