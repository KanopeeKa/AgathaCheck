import {
  acceptConnectionRequest,
  createConnectionRequest,
  disconnectOrgs,
  listConnectionsForOrg,
  revokeConnectionRequest,
} from '../../lib/orgConnections.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';

export function registerConnectionRoutes(router, pool) {
  router.post('/connection-requests/:token/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await acceptConnectionRequest(pool, req.params.token, userId);
      res.json(result);
    } catch (err) {
      if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/connections', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
      const rows = await listConnectionsForOrg(pool, req.params.orgId);
      res.json(rows.map((r) => ({
        id: r.id,
        peer_org_id: r.peer_org_id,
        peer_org_name: r.peer_org_name,
        peer_org_type: r.peer_org_type,
        peer_org_email: r.peer_org_email,
        connected_at: r.connected_at,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/connections/:otherOrgId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, otherOrgId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      await disconnectOrgs(pool, orgId, otherOrgId, orgId);
      res.json({ disconnected: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/connection-requests', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;
    const data = req.body || {};
    const targetOrgId = data.target_org_id || data.targetOrgId;
    if (!targetOrgId) {
      return res.status(400).json({ error: 'target_org_id is required' });
    }
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const result = await createConnectionRequest(pool, {
        requestingOrgId: orgId,
        targetOrgId,
        createdBy: userId,
      });
      res.status(201).json(result);
    } catch (err) {
      if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/connection-requests', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const result = await pool.query(
        `SELECT id, requesting_org_id, target_org_id, token, status, expires_at, created_at, revoked_at
         FROM org_connection_requests
         WHERE requesting_org_id = $1 OR target_org_id = $1
         ORDER BY created_at DESC`,
        [orgId],
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/connection-requests/:requestId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, requestId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      await revokeConnectionRequest(pool, requestId, orgId);
      res.json({ revoked: true });
    } catch (err) {
      if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });
}
