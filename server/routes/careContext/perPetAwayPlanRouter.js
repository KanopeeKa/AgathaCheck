import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { loadPerPetAwayPlan } from '../../lib/care/awayPlan/loadPerPetAwayPlan.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  loadAbsenceForUser,
  loadAbsencePets,
} from './plannedAbsenceStore.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 */
export function registerPerPetAwayPlanRoutes(router, pool) {
  router.get('/:id/pets/:petId/away-plan', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const absenceRow = await loadAbsenceForUser(pool, req.params.id, userId);
    if (!absenceRow) return res.status(404).json({ error: 'Not found' });

    const petRows = await loadAbsencePets(pool, absenceRow.id);
    const petRow = petRows.find((row) => row.pet_id === req.params.petId);
    if (!petRow) return res.status(404).json({ error: 'Pet is not on this absence' });

    const payload = await loadPerPetAwayPlan(pool, absenceRow, petRow, userId);
    res.json(payload);
  }));

  router.get('/:id/pets/:petId/status', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const absenceRow = await loadAbsenceForUser(pool, req.params.id, userId);
    if (!absenceRow) return res.status(404).json({ error: 'Not found' });

    const petRows = await loadAbsencePets(pool, absenceRow.id);
    const petRow = petRows.find((row) => row.pet_id === req.params.petId);
    if (!petRow) return res.status(404).json({ error: 'Pet is not on this absence' });

    const payload = await loadPerPetAwayPlan(pool, absenceRow, petRow, userId);
    res.json({
      absence_id: payload.absence_id,
      pet_id: payload.pet_id,
      status: payload.status,
      review_care_item_count: payload.review_care_item_count,
      coverage_state: payload.coverage.coverage_state,
    });
  }));
}
