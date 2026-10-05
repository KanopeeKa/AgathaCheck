import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import {
  closeSeriesCommand,
  reopenSeriesCommand,
} from '../../lib/care/occurrence/index.js';
import { careItemWire } from '../../lib/care/item/index.js';
import { loadLinkedWeightsForOccurrences } from '../../lib/care/observations/weightFulfilmentService.js';
import { extractUserId, historyToMap } from './shared.js';
import { handleCommand } from './occurrencesRouter.js';

async function entryBody(pool, out, req) {
  return careItemWire(pool, out.entry, req, { openRows: out.openOccurrences, asOf: out.asOf });
}

export function registerCompletionRoutes(router, pool) {
  router.post('/:id/close', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => closeSeriesCommand(ctx),
    audit: () => ({ action: 'health_entry.closed', metadata: {}, activity: 'close' }),
    respond: async (out) => ({ body: await entryBody(pool, out, req) }),
  }));

  router.post('/:id/reopen', (req, res) => handleCommand(pool, req, res, {
    command: (ctx) => reopenSeriesCommand(ctx),
    audit: () => ({ action: 'health_entry.reopened', metadata: {}, activity: 'reopen' }),
    respond: async (out) => ({ body: await entryBody(pool, out, req) }),
  }));

  router.get('/:id/history', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const result = await pool.query(
        `SELECT ho.id, ho.health_entry_id, ho.status, ho.notes, ho.completed_on,
          ho.marked_by_user_id,
          ho.scheduled_date AS due_date,
          COALESCE(ho.marked_at, ho.updated_at) AS changed_at,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM health_occurrences ho
         LEFT JOIN users u ON u.id = ho.marked_by_user_id
         WHERE ho.health_entry_id = $1 AND ho.status IN ('completed', 'skipped')
         ORDER BY COALESCE(ho.marked_at, ho.updated_at) DESC, ho.scheduled_date DESC`,
        [req.params.id]
      );
      const completedIds = result.rows
        .filter((r) => r.status === 'completed')
        .map((r) => r.id);
      const linkedWeights = await loadLinkedWeightsForOccurrences(pool, completedIds);
      res.json(result.rows.map((row) => {
        const mapped = historyToMap(row);
        if (row.status === 'completed') {
          mapped.linked_weight = linkedWeights.get(row.id) ?? null;
        }
        return mapped;
      }));
    } catch (err) {
      throw err;
    }
  }));
}
