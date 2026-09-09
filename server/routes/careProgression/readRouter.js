import { publicError } from '../../config/security.js';
import { CareFamilyCapabilityPolicy } from '../../lib/care/capabilities.js';
import { loadMilestonesForPet } from '../../lib/care/progression/careMilestoneService.js';
import { loadEstablishmentsForPet } from '../../lib/care/progression/weightEstablishmentService.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql } from '../../lib/petAccess.js';
import { extractUserId } from '../pets/shared.js';

/**
 * GET /api/pets/:petId/care-progression — establishment + milestones read model (CP-1 stub).
 */
export function registerCareProgressionReadRoutes(router, pool) {
  router.get('/:id/care-progression', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { id: petId } = req.params;
    try {
      if (!CareFamilyCapabilityPolicy.supportsProgressionRead()) {
        return res.status(503).json({ error: 'Care progression unavailable' });
      }
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const petResult = await pool.query(
        `SELECT p.id FROM pets p
         WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
        [petId, userId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const [establishments, milestones] = await Promise.all([
        loadEstablishmentsForPet(pool, petId),
        loadMilestonesForPet(pool, petId),
      ]);
      return res.json({ establishments, milestones });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
