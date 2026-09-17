import express from 'express';

import { createApiLimiter } from '../config/rateLimit.js';
import { publicError } from '../config/security.js';
import { extractUserId } from '../lib/requireAuth.js';
import {
  createTag,
  deleteTag,
  listUserTagsWithPetIds,
  renameTag,
  TagNameConflictError,
  TagNotFoundError,
  TagValidationError,
} from '../lib/petTags.js';

export default function petTagsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const tags = await listUserTagsWithPetIds(pool, userId);
      res.json(tags);
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pet tags') });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const tag = await createTag(pool, userId, req.body?.name);
      res.status(201).json(tag);
    } catch (err) {
      if (err instanceof TagValidationError) {
        return res.status(400).json({ error: err.message });
      }
      if (err instanceof TagNameConflictError) {
        return res.status(409).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err, 'Error creating pet tag') });
    }
  });

  router.patch('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const tag = await renameTag(pool, userId, req.params.id, req.body?.name);
      res.json(tag);
    } catch (err) {
      if (err instanceof TagValidationError) {
        return res.status(400).json({ error: err.message });
      }
      if (err instanceof TagNotFoundError) {
        return res.status(404).json({ error: err.message });
      }
      if (err instanceof TagNameConflictError) {
        return res.status(409).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err, 'Error renaming pet tag') });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await deleteTag(pool, userId, req.params.id);
      res.status(204).send();
    } catch (err) {
      if (err instanceof TagNotFoundError) {
        return res.status(404).json({ error: err.message });
      }
      res.status(500).json({ error: publicError(err, 'Error deleting pet tag') });
    }
  });

  return router;
}
