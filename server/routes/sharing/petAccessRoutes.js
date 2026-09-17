import { publicError } from '../../config/security.js';
import { registerPetInviteListRoute } from './inviteRoutes.js';
import {
  changeRole,
  listAccess,
  listShareLinks,
  removeAccess,
  stopFollowing,
} from '../../services/sharing/shareAccessService.js';
import { extractUserId, withOptionalTransaction } from '../pets/shared.js';

export function registerPetAccessRoutes(router, pool) {
  registerPetInviteListRoute(router, pool);

  router.get('/:id/share-links', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      const result = await listShareLinks(pool, userId, id);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result.links);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/follow', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      const result = await stopFollowing(pool, userId, id);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json({ message: result.message });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/access', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      const result = await listAccess(pool, userId, id);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result.access);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/access/:targetUserId/role', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, targetUserId } = req.params;
    const nextRole = req.body?.role || req.body?.access_role;
    try {
      const result = await changeRole(pool, {
        userId,
        petId: id,
        targetUserId,
        nextRole,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json({ user_id: result.user_id, role: result.role });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/access/:targetUserId', async (req, res) => {
    const actorId = extractUserId(req);
    if (!actorId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, targetUserId } = req.params;
    try {
      await withOptionalTransaction(pool, async (db) => {
        const result = await removeAccess(db, { actorId, petId: id, targetUserId });
        if (result.error) {
          const err = new Error(result.error);
          err.status = result.status;
          throw err;
        }
      });
      res.json({ message: 'Access removed' });
    } catch (err) {
      if (err.status === 404) {
        return res.status(404).json({ error: 'Access not found' });
      }
      res.status(500).json({ error: publicError(err) });
    }
  });
}
