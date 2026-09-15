import { publicError } from '../../config/security.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { explainGap } from '../../lib/care/schedule/explainGap.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { extractUserId } from './shared.js';

async function loadEntry(pool, entryId, userId) {
  if (!(await userCanManageHealthEntry(pool, entryId, userId))) {
    return null;
  }
  const result = await pool.query(
    'SELECT * FROM health_entries WHERE id = $1',
    [entryId],
  );
  return result.rows[0] || null;
}

function dateWindowFromRequest(req) {
  const q = req.query || {};
  return {
    fromDate: normalizeCalendarDateInput(q.from_date || q.fromDate),
    toDate: normalizeCalendarDateInput(q.to_date || q.toDate),
  };
}

export function registerScheduleExplainRoutes(router, pool) {
  router.get('/:id/schedule-explain', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const entry = await loadEntry(pool, req.params.id, userId);
      if (!entry) return res.status(404).json({ error: 'Entry not found' });
      const { fromDate, toDate } = dateWindowFromRequest(req);
      const result = await explainGap(pool, { entry, fromDate, toDate });
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
