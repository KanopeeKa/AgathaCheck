import { asyncHandler } from '../../lib/http/asyncHandler.js';
import {
  careItemReadResponse,
  careItemsWire,
} from '../../lib/care/item/index.js';
import { extractUserId } from './shared.js';
import {
  exportHealthEntriesCsv,
  getHealthEntryForUser,
  listHealthEntriesForUser,
} from '../../lib/health/healthEntryReadService.js';

export function registerCrudReadRoutes(router, pool) {
  router.get('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.query.pet_id || req.query.petId;
    const out = await listHealthEntriesForUser(pool, userId, petId);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(await careItemsWire(pool, out.rows, req));
  }));

  router.get('/export', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const csv = await exportHealthEntriesCsv(pool, userId);
    res.setHeader('Content-Type', 'text/csv');
    res.send(csv);
  }));

  router.get('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await getHealthEntryForUser(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(await careItemReadResponse(pool, out.row, req.params.id, req));
  }));
}
