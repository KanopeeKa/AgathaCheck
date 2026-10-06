import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { extractUserId } from './shared.js';
import {
  listOccurrencesForEntry,
  loadManagedEntry,
} from '../../lib/health/occurrenceListService.js';

export function registerOccurrenceListRoutes(router, pool) {
  router.get('/:id/occurrences', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const entry = await loadManagedEntry(pool, req.params.id, userId);
    if (!entry) return res.status(404).json({ error: 'Entry not found' });
    const status = req.query.status || 'open';
    const wire = await listOccurrencesForEntry(pool, entry, { status, req });
    return res.json(wire);
  }));
}
