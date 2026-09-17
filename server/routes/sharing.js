import express from 'express';

import { createApiLimiter } from '../config/rateLimit.js';
import { publicError } from '../config/security.js';
import { extractUserId } from '../lib/requireAuth.js';
import {
  acceptLink,
  createLink,
  getPreview,
  hidePet,
  listHidden,
  revokeLink,
} from '../services/sharing/shareLinkService.js';
import { registerInviteRoutes } from './sharing/inviteRoutes.js';
import { registerShareAccessAggregateRoutes } from './sharing/shareAccessAggregateRoutes.js';

export default function sharingRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  registerInviteRoutes(router, pool);
  registerShareAccessAggregateRoutes(router, pool);

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await createLink(pool, {
        userId,
        petId: req.body?.pet_id || req.body?.petId,
        expiresInDays: req.body?.expires_in_days ?? req.body?.expiresInDays,
        accessRole: req.body?.access_role ?? req.body?.accessRole,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.status(result.status).json({
        share_code: result.share_code,
        link_id: result.link_id,
        expires_at: result.expires_at,
        expires_in_days: result.expires_in_days,
        access_role: result.access_role,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/links/:linkId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await revokeLink(pool, { userId, linkId: req.params.linkId });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json({ message: result.message });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/hidden', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const rows = await listHidden(pool, userId);
      res.json(rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:petId/hide', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await hidePet(pool, {
        userId,
        petId: req.params.petId,
        hidden: req.body?.hidden,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json({ message: result.message });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:code', async (req, res) => {
    const { code } = req.params;
    if (code === 'hidden') {
      return res.status(404).json({ error: 'Not found' });
    }
    try {
      const result = await getPreview(pool, code);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { code } = req.params;
    if (code === 'hidden' || code === 'links') {
      return res.status(404).json({ error: 'Not found' });
    }
    try {
      const result = await acceptLink(pool, { userId, code });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
