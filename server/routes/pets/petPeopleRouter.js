import { publicError } from '../../config/security.js';
import { asPeopleError, petPeople } from '../../lib/people/index.js';
import { extractUserId } from './shared.js';

function sendPeopleError(res, err) {
  const pe = asPeopleError(err);
  if (pe) return res.status(pe.status).json(pe.toJson());
  return null;
}

export function registerPetPeopleRoutes(router, pool) {
  router.get('/:petId/people', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId } = req.params;
    try {
      const result = await petPeople(pool, userId, petId);
      if (!result) {
        return res.status(403).json({ error: 'Forbidden', code: 'forbidden' });
      }
      res.json(result);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });
}
