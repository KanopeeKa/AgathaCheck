import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { listPetPlannedAbsences } from '../../lib/care/awayPlan/listPetPlannedAbsences.js';
import { userCanManageProfile } from '../../lib/petAccess.js';
import { extractUserId } from '../../lib/requireAuth.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 */
export function registerPetPlannedAbsencesRoutes(router, pool) {
  router.get('/:petId/planned-absences', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const { petId } = req.params;
    if (!(await userCanManageProfile(pool, petId, userId))) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const payload = await listPetPlannedAbsences(pool, petId, userId);
    res.json(payload);
  }));
}
