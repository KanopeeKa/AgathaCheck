import { publicError } from '../../config/security.js';
import {
  assignTagToPet,
  TagNotFoundError,
  unassignTagFromPet,
} from '../../lib/petTags.js';
import { extractUserId } from './shared.js';

export function registerPetTagsRoutes(router, pool) {
  router.post('/:petId/tags', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId } = req.params;
    const tagId = req.body?.tag_id;
    if (!tagId || typeof tagId !== 'string') {
      return res.status(400).json({ error: 'tag_id is required' });
    }
    try {
      await assignTagToPet(pool, userId, petId, tagId);
      res.status(204).send();
    } catch (err) {
      if (err instanceof TagNotFoundError) {
        return res.status(404).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err, 'Error assigning pet tag') });
    }
  });

  router.delete('/:petId/tags/:tagId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { petId, tagId } = req.params;
    try {
      await unassignTagFromPet(pool, userId, petId, tagId);
      res.status(204).send();
    } catch (err) {
      if (err instanceof TagNotFoundError) {
        return res.status(404).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err, 'Error unassigning pet tag') });
    }
  });
}
