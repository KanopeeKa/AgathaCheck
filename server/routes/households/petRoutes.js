import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { removeOwnerPetFromHousehold } from '../../lib/households/pets/index.js';

export function registerHouseholdPetRoutes(router, pool) {
  router.delete('/:id/pets/:petId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await removeOwnerPetFromHousehold(
        pool,
        userId,
        req.params.id,
        req.params.petId,
      );
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
