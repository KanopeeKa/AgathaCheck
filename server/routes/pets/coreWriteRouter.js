import { asyncHandler } from '../../lib/http/asyncHandler.js';
import {
  createPet,
  deleteOwnedPet,
  rejectInvalidPetWeight,
  updatePet,
} from '../../lib/pets/petCoreCommandService.js';
import { rejectFrozenOrganizationIdOnPetWrite } from '../../lib/frozenDomains.js';
import { extractUserId } from './shared.js';

export function registerCoreWriteRoutes(router, pool) {
  router.post('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    if (rejectFrozenOrganizationIdOnPetWrite(req, res)) return;
    try {
      const { weight } = req.body;
      if (rejectInvalidPetWeight(weight, res)) return;
      const out = await createPet(pool, userId, req.body, req);
      if (out.error) return res.status(out.status).json({ error: out.error });
      res.status(out.status).json(out.pet);
    } catch (err) {
      if (err.status && err.body) {
        return res.status(err.status).json(err.body);
      }
      throw err;
    }
  }, { prodMessage: 'Error creating pet', devMessage: (err) => `Error creating pet: ${err.message}` }));

  router.put('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    if (rejectFrozenOrganizationIdOnPetWrite(req, res)) return;
    try {
      const { weight } = req.body;
      if (rejectInvalidPetWeight(weight, res)) return;
      const out = await updatePet(pool, userId, req.params.id, req.body, req);
      if (out.error) return res.status(out.status).json({ error: out.error });
      res.json(out.pet);
    } catch (err) {
      if (err.status && err.body) {
        return res.status(err.status).json(err.body);
      }
      throw err;
    }
  }, { prodMessage: 'Error updating pet', devMessage: (err) => `Error updating pet: ${err.message}` }));

  router.delete('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await deleteOwnedPet(pool, userId, req.params.id, req);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.result);
  }, { prodMessage: 'Error deleting pet', devMessage: (err) => `Error deleting pet: ${err.message}` }));
}
