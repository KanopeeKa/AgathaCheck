import { createNotification } from '../../lib/notificationHelper.js';
import {
  cancelAdoptionJourney,
  completeAdoptionJourneyConditions,
  getJourneyForSession,
  journeyToMap,
  startAdoptionJourney,
} from '../../lib/adoptionJourneys.js';
import { loadPlacementDetail, placementToMap } from '../../lib/fosterPlacements.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

async function loadPlacementForOrg(pool, placementId, orgId) {
  const placementResult = await pool.query(
    'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
    [placementId, orgId],
  );
  return placementResult.rows[0] ?? null;
}

async function loadPetName(pool, petId) {
  const result = await pool.query('SELECT name FROM pets WHERE id = $1', [petId]);
  return result.rows[0]?.name || 'the pet';
}

function placementWithJourneyResponse(placement, journey) {
  const detail = placementToMap(placement);
  return {
    ...detail,
    adoption_journey: journey ? journeyToMap(journey) : null,
  };
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

  router.post('/:orgId/placements/:id/adoption-journey/start', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const adoptionConditions = (data.adoption_conditions || data.adoptionConditions || '').trim();

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await startAdoptionJourney(pool, {
        placement,
        adoptionConditions,
        createdBy: userId,
        auditContext: { req },
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      const petName = await loadPetName(pool, placement.pet_id);
      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption ready to confirm',
        message: adoptionConditions
          ? `${petName} is ready for adoption once pre-adoption conditions are met.`
          : `Please confirm adoption of ${petName}.`,
        type: 'general',
      });

      res.json(placementWithJourneyResponse(result.placement, result.journey));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/adoption-journey/complete-conditions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await completeAdoptionJourneyConditions(pool, placement);
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      const petName = await loadPetName(pool, placement.pet_id);
      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption ready to confirm',
        message: `Pre-adoption conditions for ${petName} are complete. Please confirm adoption.`,
        type: 'general',
      });

      res.json(placementWithJourneyResponse(result.placement, result.journey));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/adoption-journey/cancel', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }

      const result = await cancelAdoptionJourney(pool, placement, endDate);
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }

      res.json(placementWithJourneyResponse(result.placement, null));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
