import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { ensureOpenOccurrence } from '../../lib/care/schedule/ensureOpenOccurrence.js';
import { extractUserId } from './shared.js';
import { loadEntry } from './occurrencesRouter.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 * @param {{ asOfContextForEntry: Function }} deps
 */
export function registerEnsureOpenOccurrenceRoutes(router, pool, deps) {
  router.post('/:id/occurrences/ensure-open', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const body = req.body || {};
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const asOfCtx = await deps.asOfContextForEntry(pool, entry, req);
      const requestedRaw = body.scheduled_date ?? body.scheduledDate;
      const requestedDateIso = requestedRaw
        ? normalizeCalendarDateInput(requestedRaw)
        : null;
      if (requestedRaw && !requestedDateIso) {
        return res.status(400).json({ error: 'Invalid scheduled_date' });
      }

      const result = await ensureOpenOccurrence(pool, {
        entry,
        requestedDateIso,
        todayIso: asOfCtx.todayIso,
      });

      if (!result.ok) {
        if (result.error === 'not_open_head') {
          return res.status(400).json({
            error: 'Requested date is not the open head occurrence',
            head_date: result.head_date,
          });
        }
        if (result.error === 'entry_paused') {
          return res.status(400).json({ error: 'Care item is paused' });
        }
        return res.status(400).json({ error: 'No open date to materialise' });
      }

      res.json({
        occurrences: result.occurrences,
        created: result.created,
        next_due_date: result.next_due_date,
        head_date: result.head_date,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
