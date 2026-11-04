import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { careItemWire, isItemClosed } from '../../lib/care/item/index.js';
import { getHealthEntryForUser } from '../../lib/health/healthEntryReadService.js';
import { sendCareCommandError } from '../../lib/care/occurrence/index.js';
import { updateHealthEntry } from '../../lib/health/healthEntryWriteService.js';
import { extractUserId } from './shared.js';

export function registerCrudUpdateRoutes(router, pool) {
  router.put('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const existing = await getHealthEntryForUser(pool, userId, req.params.id);
      if (existing.error) {
        return res.status(existing.status).json({ error: existing.error });
      }
      if (isItemClosed(existing.row)) {
        return res.status(409).json({
          error: 'This care is closed',
          code: 'care_item_closed',
        });
      }
      const out = await updateHealthEntry(pool, userId, req.params.id, req.body, req);
      if (out.error) {
        return res.status(out.status).json({
          error: out.error,
          ...(out.code ? { code: out.code } : {}),
        });
      }
      res.json(await careItemWire(pool, out.entry, req, {
        openRows: out.openRows,
        asOf: out.asOf,
      }));
    } catch (err) {
      if (sendCareCommandError(res, err)) return;
      throw err;
    }
  }));
}
