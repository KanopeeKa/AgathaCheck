import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  deleteAllPetData,
  notifyPassedAwayCollaborators,
} from '../../lib/petDataLifecycle.js';
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
      const result = await deleteAllPetData(pool, petId, { actorUserId: userId, req });
      res.status(200).json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/passed-away', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.LIFECYCLE_MANAGE))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const petName =
        req.body?.pet_name
        || (await pool.query('SELECT name FROM pets WHERE id = $1', [petId])).rows[0]?.name
        || null;
      const notifiedCount = await notifyPassedAwayCollaborators(pool, {
        petId,
        ownerId: userId,
        petName,
      });
      res.status(200).json({
        passed_away: true,
        pet_id: petId,
        notified_count: notifiedCount,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
