import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { extractUserId } from '../pets/shared.js';
import { dismissSafeguard, listActiveSafeguards } from './safeguardsService.js';

export function registerSafeguardRoutes(router, pool) {
  router.get('/:id/care-safeguards', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const safeguards = await listActiveSafeguards(pool, userId, petId);
      if (safeguards === null) return res.status(404).json({ error: 'Pet not found' });
      res.json(safeguards);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/care-safeguards/:safeguardId/dismiss', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, safeguardId } = req.params;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const dismissed = await dismissSafeguard(pool, userId, petId, safeguardId);
      if (dismissed === null) return res.status(404).json({ error: 'Pet not found' });
      if (dismissed === undefined) {
        return res.status(404).json({ error: 'Safeguard not found' });
      }
      return res.json(dismissed);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
