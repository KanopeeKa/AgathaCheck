import { publicError } from '../../config/security.js';
import { CareFamilyCapabilityPolicy } from '../../lib/care/capabilities.js';
import {
  acknowledgeBundlePresented,
  loadPendingMoments,
} from '../../lib/care/progression/careMilestoneService.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { accessiblePetSql } from '../../lib/petAccess.js';
import { extractUserId } from '../pets/shared.js';

async function assertPetHealthView(pool, userId, petId) {
  if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
    return { status: 403, body: { error: 'Forbidden' } };
  }
  const petResult = await pool.query(
    `SELECT p.id FROM pets p
     WHERE p.id = $1 AND ${accessiblePetSql('p', '$2')}`,
    [petId, userId],
  );
  if (petResult.rows.length === 0) {
    return { status: 404, body: { error: 'Pet not found' } };
  }
  return null;
}

/**
 * GET /api/pets/:petId/care-progression/pending-moments — per-user presentation candidates (CP-4).
 * POST /api/pets/:petId/care-progression/moments/:bundleId/acknowledge-presented — render ack (CP-4).
 */
export function registerCareProgressionMomentsRoutes(router, pool) {
  router.get('/:id/care-progression/pending-moments', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { id: petId } = req.params;
    try {
      if (!CareFamilyCapabilityPolicy.supportsProgressionRead()) {
        return res.status(503).json({ error: 'Care progression unavailable' });
      }
      const accessError = await assertPetHealthView(pool, userId, petId);
      if (accessError) return res.status(accessError.status).json(accessError.body);

      const pending = await loadPendingMoments(pool, petId, userId);
      return res.json(pending);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/care-progression/moments/:bundleId/acknowledge-presented', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { id: petId, bundleId } = req.params;
    try {
      if (!CareFamilyCapabilityPolicy.supportsProgressionRead()) {
        return res.status(503).json({ error: 'Care progression unavailable' });
      }
      const accessError = await assertPetHealthView(pool, userId, petId);
      if (accessError) return res.status(accessError.status).json(accessError.body);

      const outcome = await acknowledgeBundlePresented(pool, {
        petId,
        userId,
        bundleId,
      });
      if (!outcome.acknowledged) {
        return res.status(404).json({ error: 'Moment bundle not found' });
      }
      return res.json(outcome);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
