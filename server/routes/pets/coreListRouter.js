import { asyncHandler } from '../../lib/http/asyncHandler.js';
import {
  getPetDetailForUser,
  listAllAccessiblePets,
  listOwnedPets,
} from '../../lib/pets/petCoreQueryService.js';
import { extractUserId } from './shared.js';

export function registerCoreListRoutes(router, pool) {
  router.get('/all', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const pets = await listAllAccessiblePets(pool, userId);
    res.json(pets);
  }, { prodMessage: 'Error fetching pets', devMessage: (err) => `Error fetching pets: ${err.message}` }));

  router.get('/', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const pets = await listOwnedPets(pool, userId);
    res.json(pets);
  }, { prodMessage: 'Error fetching pets', devMessage: (err) => `Error fetching pets: ${err.message}` }));

  router.get('/:id', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const out = await getPetDetailForUser(pool, userId, req.params.id);
    if (out.error) return res.status(out.status).json({ error: out.error });
    res.json(out.pet);
  }, { prodMessage: 'Error fetching pet', devMessage: (err) => `Error fetching pet: ${err.message}` }));
}
