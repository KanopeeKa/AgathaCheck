import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { applyAccountSecurityFeedback } from '../../lib/account/accountSecurityNotifications.js';

export function registerAccountSecurityFeedbackRoutes(router, pool) {
  router.post('/:id/account-security-feedback', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const action = req.body?.action;
    if (action !== 'this_was_me' && action !== 'start_secure_flow') {
      return res.status(400).json({ error: 'Invalid action' });
    }
    try {
      const outcome = await applyAccountSecurityFeedback(
        pool,
        userId,
        req.params.id,
        action,
      );
      if (outcome.error) {
        return res.status(outcome.status).json({ error: outcome.error });
      }
      res.json(outcome.body);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
