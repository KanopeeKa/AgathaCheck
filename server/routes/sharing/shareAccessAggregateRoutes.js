import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { listAccessForPets } from '../../services/sharing/shareAccessService.js';

function parsePetIds(req) {
  const raw = req.query?.pet_ids ?? req.query?.petIds;
  if (!raw) return [];
  if (Array.isArray(raw)) return raw;
  return String(raw).split(',').map((id) => id.trim()).filter(Boolean);
}

export function registerShareAccessAggregateRoutes(router, pool) {
  router.get('/access', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petIds = parsePetIds(req);
    if (petIds.length === 0) {
      return res.status(400).json({ error: 'pet_ids is required' });
    }
    try {
      const result = await listAccessForPets(pool, userId, petIds);
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
