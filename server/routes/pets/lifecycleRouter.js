import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { extractUserId } from './shared.js';

export function registerLifecycleRoutes(router, pool) {
  router.delete('/:id/data', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.LIFECYCLE_MANAGE))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      res.status(200).json({ deleted: true, pet_id: petId });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  // STUB: the pet's passedAway flag is persisted via PUT /api/pets/:id; this
  // endpoint only exists to notify shared users (sharing is not implemented), so
  // it acknowledges without side effects.
  router.post('/:id/passed-away', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.LIFECYCLE_MANAGE))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      res.status(200).json({ passed_away: true, pet_id: petId });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
