import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql } from '../../lib/petAccess.js';
import { reEvaluateWeightEstablishments } from '../../lib/care/progression/weightEstablishmentService.js';
import { isProduction } from '../auth/shared.js';
import { extractUserId } from '../pets/shared.js';

/**
 * POST /api/pets/:petId/care-progression/re-evaluate — internal/dev re-evaluation (CP-3).
 */
export function registerCareProgressionReEvaluateRoutes(router, pool) {
  router.post('/:id/care-progression/re-evaluate', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    if (isProduction() && process.env.CARE_PROGRESSION_INTERNAL_EVAL !== '1') {
      return res.status(404).json({ error: 'Not found' });
    }

    const { id: petId } = req.params;
    const healthEntryId = req.body?.health_entry_id || req.body?.healthEntryId || null;

    try {
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

      const results = await reEvaluateWeightEstablishments(pool, petId, healthEntryId);
      return res.json({
        results,
        internal_only: true,
      });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
