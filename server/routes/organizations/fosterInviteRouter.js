import { publicError } from '../../config/security.js';
import {
  fosterInviteByEmail,
  fosterInviteByUserId,
  fosterInviteByUserIds,
} from '../../lib/fosterInvite.js';
import { extractUserId, requirePermission } from './shared.js';

export function registerFosterInviteRoutes(router, pool) {
  router.post('/:orgId/foster-invite', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};
    const email = (data.email || '').trim();
    const userIdBody = (data.user_id || data.userId || '').trim();
    const userIds = Array.isArray(data.user_ids) ? data.user_ids : null;
    const locale = data.locale;

    try {
      if (!(await requirePermission(pool, res, orgId, userId, 'manage_fosters'))) {
        return;
      }

      let result;
      if (userIds && userIds.length > 0) {
        result = await fosterInviteByUserIds(pool, {
          orgId,
          actorUserId: userId,
          userIds,
          locale,
          req,
        });
      } else if (userIdBody) {
        result = await fosterInviteByUserId(pool, {
          orgId,
          actorUserId: userId,
          targetUserId: userIdBody,
          locale,
          req,
        });
      } else if (email) {
        result = await fosterInviteByEmail(pool, {
          orgId,
          actorUserId: userId,
          email,
          locale,
          req,
        });
      } else {
        return res.status(400).json({ error: 'email or user_ids is required' });
      }

      if (result.error) {
        return res.status(result.status || 400).json({
          error: result.error,
          errors: result.errors,
        });
      }
      res.status(result.status || 201).json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
