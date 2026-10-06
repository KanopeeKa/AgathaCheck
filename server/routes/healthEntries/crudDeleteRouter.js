import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { deleteHealthEntry } from '../../lib/health/healthEntryWriteService.js';
import { extractUserId } from './shared.js';

export function registerCrudDeleteRoutes(router, pool) {
  router.delete('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await deleteHealthEntry(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json({ deleted: true });
  }));
}
