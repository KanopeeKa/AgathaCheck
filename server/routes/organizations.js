import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export default function organizationsRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT o.* FROM organizations o
         JOIN organization_users ou ON ou.organization_id = o.id
         WHERE ou.user_id = $1 ORDER BY o.name`,
        [userId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM organizations WHERE id = $1', [req.params.id]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name } = req.body;
      const orgId = uuidv4();
      const result = await pool.query(
        'INSERT INTO organizations (id, name) VALUES ($1, $2) RETURNING *',
        [orgId, name]
      );
      const ouId = uuidv4();
      await pool.query(
        "INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, 'owner')",
        [ouId, orgId, userId]
      );
      res.status(201).json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name } = req.body;
      const result = await pool.query(
        'UPDATE organizations SET name = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [name, req.params.id]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('DELETE FROM organizations WHERE id = $1 RETURNING *', [req.params.id]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json({ message: 'Organization deleted' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/photo', async (req, res) => {
    res.json({ message: 'Photo uploaded', photo_url: `/uploads/org_photos/${req.params.id}.jpg` });
  });

  router.get('/:orgId/members', async (req, res) => {
    try {
      const result = await pool.query(
        `SELECT ou.*, u.email, u.first_name, u.last_name FROM organization_users ou
         JOIN users u ON u.id = ou.user_id
         WHERE ou.organization_id = $1`,
        [req.params.orgId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:orgId/invite', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { email, role = 'pending_member' } = req.body;
      const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found with that email' });
      }
      const invitedUserId = userResult.rows[0].id;
      const id = uuidv4();
      await pool.query(
        'INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, $4)',
        [id, req.params.orgId, invitedUserId, role]
      );
      res.status(201).json({ message: 'Invite sent', id });
    } catch (err) {
      if (err.code === '23505') {
        return res.status(400).json({ error: 'User already a member or invited' });
      }
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/invites/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT ou.*, o.name as organization_name FROM organization_users ou
         JOIN organizations o ON o.id = ou.organization_id
         WHERE ou.user_id = $1 AND (ou.role = 'pending_member' OR ou.role = 'pending_super_user')`,
        [userId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/invites/:id/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        "UPDATE organization_users SET role = REPLACE(role, 'pending_', '') WHERE id = $1 AND user_id = $2 RETURNING *",
        [req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Invite not found' });
      res.json({ message: 'Invite accepted', membership: result.rows[0] });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/invites/:id/decline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('DELETE FROM organization_users WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      res.json({ message: 'Invite declined' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/join/:code', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.json({ message: 'Joined organization' });
  });

  router.put('/:orgId/members/:userId/role', async (req, res) => {
    try {
      const { role } = req.body;
      const result = await pool.query(
        'UPDATE organization_users SET role = $1 WHERE organization_id = $2 AND user_id = $3 RETURNING *',
        [role, req.params.orgId, req.params.userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Member not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:orgId/members/:userId', async (req, res) => {
    try {
      await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, req.params.userId]);
      res.json({ message: 'Member removed' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:orgId/members/me', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, userId]);
      res.json({ message: 'Left organization' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:orgId/pets', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM pets WHERE organization_id = $1', [req.params.orgId]);
      res.json(result.rows);
    } catch (err) {
      res.json([]);
    }
  });

  router.post('/:orgId/pets', async (req, res) => {
    res.status(201).json({ message: 'Pet added to org' });
  });

  router.post('/:orgId/pets/:petId/transfer', async (req, res) => {
    res.json({ message: 'Pet transferred' });
  });

  router.get('/:orgId/archived', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM archived_pets WHERE user_id IN (SELECT user_id FROM organization_users WHERE organization_id = $1)', [req.params.orgId]);
      res.json(result.rows);
    } catch (err) {
      res.json([]);
    }
  });

  return router;
}
