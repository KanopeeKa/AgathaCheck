import { asyncHandler } from '../../lib/http/asyncHandler.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  acceptAbsenceCarerInvite,
  createAbsenceCarerInvite,
  getAbsenceCarerInvitePreview,
  revokeAbsenceCarerInvite,
  revokeAbsenceGuestGrant,
} from '../../lib/people/absenceCarerInviteService.js';

export function registerPlannedAbsenceCarerInviteRoutes(router, pool) {
  router.post('/:id/carer-invites', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const body = req.body || {};
      const result = await createAbsenceCarerInvite(pool, {
        absenceId: req.params.id,
        inviterUserId: userId,
        contactId: body.contact_id || body.contactId,
        petIds: body.pet_ids ?? body.petIds,
      });
      if (result.error) {
        return res.status(result.status).json({ error: result.error });
      }
      return res.status(result.status).json({
        invite_id: result.invite_id,
        code: result.code,
        pet_ids: result.pet_ids,
        expires_at: result.expires_at,
      });
    } catch (err) {
      throw err;
    }
  }));

  router.get('/carer-invites/code/:code', asyncHandler(async (req, res) => {
    try {
      const result = await getAbsenceCarerInvitePreview(pool, req.params.code);
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      throw err;
    }
  }));

  router.post('/carer-invites/code/:code/accept', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await acceptAbsenceCarerInvite(pool, {
        code: req.params.code,
        userId,
        userEmail: req.user?.email,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      throw err;
    }
  }));

  router.post('/carer-invites/:inviteId/accept', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await acceptAbsenceCarerInvite(pool, {
        inviteId: req.params.inviteId,
        userId,
        userEmail: req.user?.email,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      throw err;
    }
  }));

  router.delete('/carer-invites/:inviteId', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await revokeAbsenceCarerInvite(pool, {
        inviteId: req.params.inviteId,
        userId,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      throw err;
    }
  }));

  router.delete('/guest-grants/:grantId', asyncHandler(async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await revokeAbsenceGuestGrant(pool, {
        grantId: req.params.grantId,
        userId,
      });
      if (result.error) return res.status(result.status).json({ error: result.error });
      return res.json(result);
    } catch (err) {
      throw err;
    }
  }));
}
