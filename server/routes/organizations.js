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

function orgRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    type: row.type || 'professional',
    email: row.email || null,
    phone: row.phone || null,
    address: row.address || null,
    website: row.website || null,
    bio: row.bio || '',
    photo_url: row.photo_url || '',
    role: row.role || null,
    member_count: parseInt(row.member_count, 10) || 0,
    pet_count: parseInt(row.pet_count, 10) || 0,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export default function organizationsRoutes(pool) {
  const router = express.Router();

  router.get('/invites/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT ou.id, ou.organization_id, ou.role, o.name as org_name, o.type as org_type
         FROM organization_users ou
         JOIN organizations o ON o.id = ou.organization_id
         WHERE ou.user_id = $1 AND (ou.role = 'pending_member' OR ou.role = 'pending_super_user')
         ORDER BY ou.created_at DESC`,
        [userId]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        organization_id: r.organization_id,
        role: r.role,
        org_name: r.org_name,
        org_type: r.org_type,
      })));
    } catch (err) {
      res.status(500).json({ error: err.message });
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
        role: r.role,
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
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
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/join/:code', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.json({ message: 'Joined organization' });
  });

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT o.*, ou.role,
          (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
          0 as pet_count
         FROM organizations o
         JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = $1
         ORDER BY o.name`,
        [userId]
      );
      res.json(result.rows.map(orgRowToMap));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT o.*, ou.role,
          (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
          0 as pet_count
         FROM organizations o
         JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = $1
         WHERE o.id = $2`,
        [userId, req.params.id]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json(orgRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name, type, email, phone, address, website, bio, photo_url } = req.body;
      const orgId = uuidv4();
      await pool.query(
        'INSERT INTO organizations (id, name, type, email, phone, address, website, bio, photo_url) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)',
        [orgId, name || '', type || 'professional', email || null, phone || null, address || null, website || null, bio || '', photo_url || '']
      );
      const ouId = uuidv4();
      await pool.query(
        "INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, 'super_user')",
        [ouId, orgId, userId]
      );
      const result = await pool.query(
        `SELECT o.*, 'super_user' as role,
          1 as member_count, 0 as pet_count
         FROM organizations o WHERE o.id = $1`,
        [orgId]
      );
      res.status(201).json(orgRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name, type, email, phone, address, website, bio, photo_url } = req.body;
      await pool.query(
        'UPDATE organizations SET name = $1, type = $2, email = $3, phone = $4, address = $5, website = $6, bio = $7, photo_url = $8, updated_at = NOW() WHERE id = $9',
        [name || '', type || 'professional', email || null, phone || null, address || null, website || null, bio || '', photo_url || '', req.params.id]
      );
      const result = await pool.query(
        `SELECT o.*, ou.role,
          (SELECT COUNT(*) FROM organization_users WHERE organization_id = o.id) as member_count,
          0 as pet_count
         FROM organizations o
         JOIN organization_users ou ON ou.organization_id = o.id AND ou.user_id = $1
         WHERE o.id = $2`,
        [userId, req.params.id]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json(orgRowToMap(result.rows[0]));
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
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/photo', async (req, res) => {
    res.json({ message: 'Photo uploaded', photo_url: `/uploads/org_photos/${req.params.id}.jpg` });
  });

  router.get('/:orgId/members', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT ou.id, ou.role, ou.created_at, u.id as user_id, u.email, u.first_name, u.last_name, u.photo_url
         FROM organization_users ou
         JOIN users u ON u.id = ou.user_id
         WHERE ou.organization_id = $1
         ORDER BY ou.created_at`,
        [req.params.orgId]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        user_id: r.user_id,
        email: r.email,
        first_name: r.first_name,
        last_name: r.last_name,
        photo_url: r.photo_url,
        role: r.role,
        created_at: r.created_at,
      })));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/invite', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { email, role = 'member' } = req.body;
      if (!email) {
        return res.status(400).json({ error: 'Email is required' });
      }
      const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      const invitedUserId = userResult.rows[0].id;
      const pendingRole = `pending_${role}`;
      const id = uuidv4();
      await pool.query(
        'INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, $4) ON CONFLICT (organization_id, user_id) DO UPDATE SET role = $4',
        [id, req.params.id, invitedUserId, pendingRole]
      );
      res.json({ success: true, user_id: invitedUserId });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
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

  router.delete('/:orgId/members/:userId', async (req, res) => {
    try {
      await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, req.params.userId]);
      res.json({ message: 'Member removed' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:orgId/pets', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM pets WHERE organization_id = $1 ORDER BY created_at', [req.params.orgId]);
      res.json(result.rows.map(r => ({
        id: r.id,
        name: r.name,
        species: r.species,
        breed: r.breed,
        organization_id: r.organization_id,
      })));
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
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM archived_pets WHERE organization_id = $1 ORDER BY created_at DESC', [req.params.orgId]);
      res.json(result.rows);
    } catch (err) {
      res.json([]);
    }
  });

  return router;
}
