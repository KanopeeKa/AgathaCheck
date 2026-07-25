import {
  getJourneyForSession,
  journeyToMap,
} from '../../lib/adoptionJourneys.js';
import { loadPlacementDetail } from '../../lib/fosterPlacements.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

async function loadPlacementForOrg(pool, placementId, orgId) {
  const placementResult = await pool.query(
    'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
    [placementId, orgId],
  );
  return placementResult.rows[0] ?? null;
}

export function registerAdoptionJourneysRoutes(router, pool) {
  router.get('/:orgId/placements/:id/adoption-journey', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const journey = await getJourneyForSession(pool, placementId);
      if (!journey) {
        return res.status(404).json({ error: 'Adoption journey not found' });
      }

      const detail = await loadPlacementDetail(pool, placementId);
      res.json({
        adoption_journey: journeyToMap(journey),
        placement_id: placementId,
        pet_id: detail?.pet_id || placement.pet_id,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
