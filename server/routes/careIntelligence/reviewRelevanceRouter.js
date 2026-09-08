import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql } from '../../lib/petAccess.js';
import { extractUserId } from '../pets/shared.js';
import { evaluateReviewRelevance } from './reviewRelevance.js';
import { weightContextFromPetRow } from './provenance.js';

async function loadWeightMeasurements(pool, petId) {
  const result = await pool.query(
    `SELECT date, weight, unit, measurement_source
     FROM weight_entries
     WHERE pet_id = $1
     ORDER BY date ASC`,
    [petId],
  );
  return result.rows.map((row) => ({
    date: row.date,
    weight: row.weight,
    unit: row.unit || 'kg',
    measurement_source: row.measurement_source || 'guardian',
  }));
}

/**
 * Phase D internal-only review relevance evaluation (not a guardian safeguard).
 */
export function registerReviewRelevanceRoutes(router, pool) {
  router.get('/:id/review-relevance/evaluate', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId } = req.params;
    try {
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const petResult = await pool.query(
        `SELECT p.* FROM pets p
         WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
        [petId, userId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = petResult.rows[0];
      const measurements = await loadWeightMeasurements(pool, petId);
      const outcome = evaluateReviewRelevance({
        pet,
        measurements,
        weightContext: weightContextFromPetRow(pet),
      });
      return res.json({
        review_relevant: outcome.review_relevant,
        suppressed: outcome.suppressed,
        suppression_reasons: outcome.suppression_reasons,
        weight_change_spec: outcome.weight_change_spec,
        features: outcome.features,
        trace: outcome.trace,
        internal_only: true,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
