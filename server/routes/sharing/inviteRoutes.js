import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { listPendingInvitesForPetAccess } from '../../services/sharing/shareAccessService.js';
import {
  acceptShareInvite,
  createShareInvite,
  declineShareInvite,
  getInvitePreview,
  revokeShareInvite,
} from '../../services/sharing/shareInviteService.js';

export function registerInviteRoutes(router, pool) {
  router.post('/invites', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await createShareInvite(pool, {
        inviterUserId: userId,
        inviteeEmail: req.body?.invitee_email ?? req.body?.inviteeEmail,
        petIds: req.body?.pet_ids ?? req.body?.petIds,
        role: req.body?.role ?? req.body?.access_role ?? req.body?.accessRole,
        locale: req.body?.locale ?? req.headers['accept-language'],
      });
      if (result.error) {
        const body = { error: result.error };
        if (result.excluded) body.excluded = result.excluded;
        return res.status(result.status).json(body);
      }
      return res.status(result.status).json({
        invite_id: result.invite_id,
        code: result.code,
        included_pet_ids: result.included_pet_ids,
        excluded: result.excluded,
        delivery: result.delivery,
      });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/invites/code/:code', async (req, res) => {
    try {
      const result = await getInvitePreview(pool, req.params.code);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/invites/:inviteId/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await acceptShareInvite(pool, {
        inviteId: req.params.inviteId,
        userId,
        userEmail: req.user?.email,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/invites/code/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await acceptShareInvite(pool, {
        code: req.params.code,
        userId,
        userEmail: req.user?.email,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/invites/:inviteId/decline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await declineShareInvite(pool, {
        inviteId: req.params.inviteId,
        userId,
        userEmail: req.user?.email,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/invites/:inviteId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await revokeShareInvite(pool, {
        inviteId: req.params.inviteId,
        userId,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}

export function registerPetInviteListRoute(router, pool) {
  router.get('/:id/invites', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await listPendingInvitesForPetAccess(pool, userId, req.params.id);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result.invites);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
