import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { loadAbsenceForViewer } from '../../lib/care/absence/absenceVisibility.js';
import { loadPerPetAwayPlan } from '../../lib/care/awayPlan/loadPerPetAwayPlan.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  addPetToPlannedAbsence,
  patchPerPetPlannedAbsence,
  removePetFromPlannedAbsence,
} from './plannedAbsencePetUseCases.js';

/**
 * @param {import('express').Router} router
 * @param {import('pg').Pool} pool
 */
export function registerPerPetAwayPlanRoutes(router, pool) {
  router.post('/:id/pets', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await addPetToPlannedAbsence(pool, userId, req.params.id, req.body || {});
    if (out.error) return res.status(out.status).json({ error: out.error });
    if (out.payload) return res.status(out.status).json(out.payload);
    res.json(out.body);
  }));

  router.delete('/:id/pets/:petId', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await removePetFromPlannedAbsence(
      pool,
      userId,
      req.params.id,
      req.params.petId,
      req.body || {},
    );
    if (out.error) return res.status(out.status).json({ error: out.error });
    if (out.payload) return res.status(out.status).json(out.payload);
    res.json(out.body);
  }));

  router.patch('/:id/pets/:petId', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await patchPerPetPlannedAbsence(
      pool,
      userId,
      req.params.id,
      req.params.petId,
      req.body || {},
    );
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.body);
  }));

  router.get('/:id/pets/:petId/away-plan', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const viewed = await loadAbsenceForViewer(pool, req.params.id, userId);
    if (!viewed) return res.status(404).json({ error: 'Not found' });

    const petRow = viewed.petRows.find((row) => row.pet_id === req.params.petId);
    if (!petRow) return res.status(404).json({ error: 'Not found' });

    const payload = await loadPerPetAwayPlan(pool, viewed.row, petRow, userId);
    res.json(payload);
  }));

  router.get('/:id/pets/:petId/status', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    const viewed = await loadAbsenceForViewer(pool, req.params.id, userId);
    if (!viewed) return res.status(404).json({ error: 'Not found' });

    const petRow = viewed.petRows.find((row) => row.pet_id === req.params.petId);
    if (!petRow) return res.status(404).json({ error: 'Not found' });

    const payload = await loadPerPetAwayPlan(pool, viewed.row, petRow, userId);
    res.json({
      absence_id: payload.absence_id,
      pet_id: payload.pet_id,
      status: payload.status,
      review_care_item_count: payload.review_care_item_count,
      coverage_state: payload.coverage.coverage_state,
    });
  }));
}
