import { publicError } from '../../config/security.js';
import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import {
  addVetVisitOccurrenceLinks,
  completePetVetVisit,
  createPetVetVisit,
  getPetVetVisit,
  listPetVetVisits,
  removeVetVisitOccurrenceLink,
} from '../../lib/pets/vetVisits.js';
import { extractUserId } from './shared.js';

export function registerVetVisitsRoutes(router, pool) {
  router.get('/:id/vet-visits', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const pet = await pool.query('SELECT id FROM pets WHERE id = $1', [petId]);
    if (pet.rows.length === 0) return res.status(404).json({ error: 'Pet not found' });
    const payload = await listPetVetVisits(pool, petId);
    res.json(payload);
  }));

  router.post('/:id/vet-visits', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    try {
      const result = await createPetVetVisit(pool, userId, petId, req.body || {});
      if (result === null) return res.status(404).json({ error: 'Pet not found' });
      if (result.error) return res.status(400).json({ error: result.error });
      return res.status(201).json(result.visit);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  }));

  router.get('/:id/vet-visits/:visitId', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const visitId = req.params.visitId;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const visit = await getPetVetVisit(pool, petId, visitId);
    if (!visit) return res.status(404).json({ error: 'Vet visit not found' });
    res.json(visit);
  }));

  router.post('/:id/vet-visits/:visitId/complete', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const visitId = req.params.visitId;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    try {
      const result = await completePetVetVisit(pool, petId, visitId, req.body || {});
      if (result === null) return res.status(404).json({ error: 'Vet visit not found' });
      if (result.error) return res.status(400).json({ error: result.error });
      return res.json(result.visit);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  }));

  router.post('/:id/vet-visits/:visitId/occurrence-links', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const visitId = req.params.visitId;
    if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    try {
      const result = await addVetVisitOccurrenceLinks(pool, petId, visitId, req.body || {});
      if (result === null) return res.status(404).json({ error: 'Vet visit not found' });
      if (result.error) return res.status(400).json({ error: result.error });
      return res.json(result.visit);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  }));

  router.delete(
    '/:id/vet-visits/:visitId/occurrence-links/:occId',
    asyncHandler(async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      const petId = req.params.id;
      const visitId = req.params.visitId;
      const occurrenceId = req.params.occId;
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      try {
        const result = await removeVetVisitOccurrenceLink(pool, petId, visitId, occurrenceId);
        if (result === null) return res.status(404).json({ error: 'Vet visit not found' });
        if (result.error) return res.status(404).json({ error: result.error });
        return res.json(result.visit);
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    }),
  );
}
