import { createHouseholdInviteLimiter } from '../../config/rateLimit.js';
import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  acceptHouseholdInvite,
  createHouseholdInvite,
  declineHouseholdInvite,
  getHouseholdInvitePreview,
  revokeHouseholdInvite,
} from '../../lib/households/householdInviteService.js';

const householdInviteCreateLimiter = createHouseholdInviteLimiter();

export function registerHouseholdInviteRoutes(router, pool) {
  router.get('/invites/code/:code', async (req, res) => {
    try {
      const result = await getHouseholdInvitePreview(pool, req.params.code);
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
      const result = await acceptHouseholdInvite(pool, {
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

  router.post('/invites/code/:code/decline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await declineHouseholdInvite(pool, {
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

  router.post('/:id/invites', householdInviteCreateLimiter, async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const body = req.body || {};
      const result = await createHouseholdInvite(pool, {
        householdId: req.params.id,
        inviterUserId: userId,
        inviteeEmail: body.invitee_email ?? body.inviteeEmail,
        accessTier: body.access_tier ?? body.accessTier,
        isOrganiser: body.is_organiser ?? body.isOrganiser,
        contactId: body.contact_id ?? body.contactId,
        locale: body.locale ?? req.headers['accept-language'],
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.status(result.status).json({
        invite_id: result.invite_id,
        code: result.code,
        expires_at: result.expires_at,
        delivery: result.delivery,
      });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/invites/:inviteId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await revokeHouseholdInvite(pool, {
        householdId: req.params.id,
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
