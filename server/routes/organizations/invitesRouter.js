import { extractUserId } from './shared.js';
import { publicError } from '../../config/security.js';
import { normaliseRole } from '../../lib/orgRoles.js';

export function registerInvitesRoutes(router, pool) {
    router.get('/invites/pending', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const result = await pool.query(
          `SELECT ou.id, ou.organization_id, ou.role, o.name as org_name, o.type as org_type
           FROM organization_users ou
           JOIN organizations o ON o.id = ou.organization_id
           WHERE ou.user_id = $1 AND ou.role LIKE 'pending_%'
           ORDER BY ou.created_at DESC`,
          [userId]
        );
        res.json(result.rows.map(r => ({
          id: r.id,
          organization_id: r.organization_id,
          role: normaliseRole(r.role),
          org_name: r.org_name,
          org_type: r.org_type,
        })));
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/invites/:id/accept', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        const result = await pool.query(
          "UPDATE organization_users SET role = REPLACE(role, 'pending_', ''), updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING *",
          [req.params.id, userId]
        );
        if (result.rows.length === 0) return res.status(404).json({ error: 'Invite not found' });
        const r = result.rows[0];
        res.json({
          id: r.id,
          organization_id: r.organization_id,
          role: normaliseRole(r.role),
        });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/invites/:id/decline', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      try {
        await pool.query(
          "DELETE FROM organization_users WHERE id = $1 AND user_id = $2 AND role LIKE 'pending_%'",
          [req.params.id, userId]
        );
        res.json({ success: true });
      } catch (err) {
        res.status(500).json({ error: publicError(err) });
      }
    });

    router.post('/join/:code', async (req, res) => {
      const userId = extractUserId(req);
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });
      return res.status(501).json({ error: 'Not implemented' });
    });
}
