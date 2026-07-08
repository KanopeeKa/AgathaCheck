import { normalizeCalendarDateInput } from '../../../lib/calendarDate.js';
import { createNotification } from '../../../lib/notificationHelper.js';
import {
  cancelAdoptionPlacement,
  loadPlacementDetail,
  placementToMap,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  revokeFosterPetAccess,
} from '../../../lib/fosterPlacements.js';
import {
  clearOrgPetHomeHiddenForPet,
  setOrgGuardianAndCare,
} from '../../../lib/petCustody.js';
import { extractUserId, requireOrgAdmin } from '../shared.js';
import { publicError } from '../../../config/security.js';

async function loadPlacementForOrg(pool, placementId, orgId) {
  const placementResult = await pool.query(
    'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
    [placementId, orgId],
  );
  return placementResult.rows[0] ?? null;
}

async function loadPetName(pool, petId) {
  const petResult = await pool.query('SELECT name FROM pets WHERE id = $1', [petId]);
  return petResult.rows[0]?.name || 'Pet';
}

export function registerPlacementActionRoutes(router, pool) {
  router.post('/:orgId/placements/:id/end', async (req, res) => {
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
      if (![PLACEMENT_STATUS_PENDING, PLACEMENT_STATUS_IN_PROGRESS].includes(placement.status)) {
        return res.status(400).json({ error: 'Placement is not active' });
      }

      const petName = await loadPetName(pool, placement.pet_id);

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1,
             end_date = COALESCE($2, CURRENT_DATE),
             updated_at = NOW()
         WHERE id = $3
         RETURNING *`,
        [PLACEMENT_STATUS_NOT_IN_FOSTER, endDate, placementId],
      );

      if (placement.status === PLACEMENT_STATUS_IN_PROGRESS) {
        await revokeFosterPetAccess(pool, placement.pet_id, placement.foster_user_id);
        await setOrgGuardianAndCare(pool, placement.pet_id, orgId);
        await clearOrgPetHomeHiddenForPet(pool, placement.pet_id);
      }

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Foster period ended',
        message: `The foster period for ${petName} has ended.`,
        type: 'general',
      });

      res.json(placementToMap(updateResult.rows[0], { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/start-adoption', async (req, res) => {
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
      if (placement.status !== PLACEMENT_STATUS_IN_PROGRESS) {
        return res.status(400).json({ error: 'Placement must be in progress to start adoption' });
      }

      const nextStatus = adoptionConditions
        ? PLACEMENT_STATUS_PENDING_CONDITIONS
        : PLACEMENT_STATUS_WAITING_ADOPTION;

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1,
             adoption_conditions = $2,
             updated_at = NOW()
         WHERE id = $3
         RETURNING *`,
        [nextStatus, adoptionConditions, placementId],
      );

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

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updateResult.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/complete-conditions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placement = await loadPlacementForOrg(pool, placementId, orgId);
      if (!placement) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      if (placement.status !== PLACEMENT_STATUS_PENDING_CONDITIONS) {
        return res.status(400).json({ error: 'Placement is not awaiting condition completion' });
      }

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING *`,
        [PLACEMENT_STATUS_WAITING_ADOPTION, placementId],
      );

      const petName = await loadPetName(pool, placement.pet_id);

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption ready to confirm',
        message: `Pre-adoption conditions for ${petName} are complete. Please confirm adoption.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updateResult.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/cancel-adoption', async (req, res) => {
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
      if (![PLACEMENT_STATUS_WAITING_ADOPTION, PLACEMENT_STATUS_PENDING_CONDITIONS].includes(placement.status)) {
        return res.status(400).json({ error: 'Placement is not in an adoption step' });
      }

      const petName = await loadPetName(pool, placement.pet_id);
      const updated = await cancelAdoptionPlacement(pool, placement, endDate);

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption cancelled',
        message: `The adoption process for ${petName} was cancelled. The pet returns to organisation custody.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updated, { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
