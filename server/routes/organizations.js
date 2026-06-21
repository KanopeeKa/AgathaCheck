import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';

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

// Roles that may be assigned to a member. `pending_*` variants are derived from
// these for invites; anything else is rejected so callers cannot smuggle in
// arbitrary privilege strings (e.g. `pending_super_user`).
const ASSIGNABLE_ROLES = ['member', 'super_user'];

// Returns the caller's role in the org, or null if they are not a member.
async function getMemberRole(pool, orgId, userId) {
  const result = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  return result.rows.length ? result.rows[0].role : null;
}

// A confirmed member (excludes users with an outstanding pending invite).
function isActiveMember(role) {
  return !!role && !role.startsWith('pending_');
}

// Org administrators (the only role allowed to mutate org/membership state).
function isAdmin(role) {
  return role === 'super_user';
}

// Guards a route so only confirmed members proceed. Returns true if the caller
// is allowed; otherwise writes a 403 and returns false.
async function requireMember(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isActiveMember(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return false;
  }
  return true;
}

// Guards a route so only org admins (super_user) proceed.
async function requireAdmin(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isAdmin(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return false;
  }
  return true;
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
        role: r.role,
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
      res.status(500).json({ error: publicError(err) });
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
      res.status(500).json({ error: publicError(err) });
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
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.id, userId))) return;
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
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.id, userId))) return;
      const result = await pool.query('DELETE FROM organizations WHERE id = $1 RETURNING *', [req.params.id]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Organization not found' });
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/photo', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.id, userId))) return;
      res.json({ message: 'Photo uploaded', photo_url: `/uploads/org_photos/${req.params.id}.jpg` });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/members', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireMember(pool, res, req.params.orgId, userId))) return;
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
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/invite', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.id, userId))) return;
      const { email, role = 'member' } = req.body;
      if (!email) {
        return res.status(400).json({ error: 'Email is required' });
      }
      if (!ASSIGNABLE_ROLES.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
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
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:orgId/members/:userId/role', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.orgId, userId))) return;
      const { role } = req.body;
      if (!ASSIGNABLE_ROLES.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
      }
      const result = await pool.query(
        'UPDATE organization_users SET role = $1 WHERE organization_id = $2 AND user_id = $3 RETURNING *',
        [role, req.params.orgId, req.params.userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Member not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/members/me', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, userId]);
      res.json({ message: 'Left organization' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/members/:userId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.orgId, userId))) return;
      await pool.query('DELETE FROM organization_users WHERE organization_id = $1 AND user_id = $2', [req.params.orgId, req.params.userId]);
      res.json({ message: 'Member removed' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/pets', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireMember(pool, res, req.params.orgId, userId))) return;
      const result = await pool.query('SELECT * FROM pets WHERE organization_id = $1 ORDER BY created_at', [req.params.orgId]);
      res.json(result.rows.map(r => ({
        id: r.id,
        name: r.name,
        species: r.species,
        breed: r.breed,
        organization_id: r.organization_id,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.orgId, userId))) return;
      res.status(201).json({ message: 'Pet added to org' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets/:petId/transfer', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireAdmin(pool, res, req.params.orgId, userId))) return;
      res.json({ message: 'Pet transferred' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/archived', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireMember(pool, res, req.params.orgId, userId))) return;
      const result = await pool.query('SELECT * FROM archived_pets WHERE organization_id = $1 ORDER BY created_at DESC', [req.params.orgId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
