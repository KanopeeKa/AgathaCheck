import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { patchHouseholdMember } from '../../lib/households/membership/index.js';

export function registerHouseholdMemberRoutes(router, pool) {
  router.patch('/:id/members/:userId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await patchHouseholdMember(
        pool,
        userId,
        req.params.id,
        req.params.userId,
        req.body || {},
      );
      if (result.error) {
        const body = { error: result.error };
        if (result.code) body.code = result.code;
        return res.status(result.status).json(body);
      }
      return res.json(result.member);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });
}
