import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { careItemWire } from '../../lib/care/item/index.js';
import { sendCareCommandError } from '../../lib/care/occurrence/index.js';
import { createHealthEntry } from '../../lib/health/healthEntryWriteService.js';
import { extractUserId } from './shared.js';

export function registerCrudCreateRoutes(router, pool) {
  router.post('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const out = await createHealthEntry(pool, userId, req.body, req);
      if (out.error) {
        return res.status(out.status).json({
          error: out.error,
          ...(out.code ? { code: out.code } : {}),
        });
      }
      res.status(out.status).json(await careItemWire(pool, out.entry, req, {
        openRows: out.openRows,
        asOf: out.asOf,
      }));
    } catch (err) {
      if (sendCareCommandError(res, err)) return;
      throw err;
    }
  }));
}
