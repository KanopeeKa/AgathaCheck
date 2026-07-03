import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { dateToIsoDate, normalizeCalendarDateInput } from '../lib/calendarDate.js';
import { createNotification, userDisplayName } from '../lib/notificationHelper.js';
import {
  cancelAdoptionPlacement,
  getActivePlacementForPet,
  loadPlacementDetail,
  OPEN_PLACEMENT_STATUSES,
  placementToMap,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  revokeFosterPetAccess,
} from '../lib/fosterPlacements.js';
import { transferOrgPetToUser } from '../lib/orgPetTransfer.js';
import {
  ASSIGNABLE_ROLES,
  ORG_ROLE_ADMIN,
  ORG_ROLE_SUPER_ADMIN,
  assignableRolesFor,
  canAssignRole,
  fosterParentMemberRolesSql,
  isActiveMember,
  isFosterParentMember,
  isOrgAdmin,
  isSuperAdmin,
  normaliseRole,
} from '../lib/orgRoles.js';

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

async function getMemberRole(pool, orgId, userId) {
  const result = await pool.query(
    'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
    [orgId, userId],
  );
  return result.rows.length ? normaliseRole(result.rows[0].role) : null;
}

async function requireMember(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isActiveMember(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}

async function requireOrgAdmin(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isOrgAdmin(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
}

async function requireSuperAdmin(pool, res, orgId, userId) {
  const role = await getMemberRole(pool, orgId, userId);
  if (!isSuperAdmin(role)) {
    res.status(403).json({ error: 'Forbidden' });
    return null;
  }
  return role;
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
      res.json(result.rows.map((row) => orgRowToMap({ ...row, role: normaliseRole(row.role) })));
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
      res.json(orgRowToMap({ ...result.rows[0], role: normaliseRole(result.rows[0].role) }));
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
        `INSERT INTO organization_users (id, organization_id, user_id, role) VALUES ($1, $2, $3, '${ORG_ROLE_SUPER_ADMIN}')`,
        [ouId, orgId, userId]
      );
      const result = await pool.query(
        `SELECT o.*, '${ORG_ROLE_SUPER_ADMIN}' as role,
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
      if (!(await requireSuperAdmin(pool, res, req.params.id, userId))) return;
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
      res.json(orgRowToMap({ ...result.rows[0], role: normaliseRole(result.rows[0].role) }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireSuperAdmin(pool, res, req.params.id, userId))) return;
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
      if (!(await requireOrgAdmin(pool, res, req.params.id, userId))) return;
      res.json({ message: 'Photo uploaded', photo_url: `/uploads/org_photos/${req.params.id}.jpg` });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/members', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
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
        role: normaliseRole(r.role),
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
      const actorRole = await requireOrgAdmin(pool, res, req.params.id, userId);
      if (!actorRole) return;
      const { email, role = ORG_ROLE_ADMIN } = req.body;
      if (!email) {
        return res.status(400).json({ error: 'Email is required' });
      }
      if (!ASSIGNABLE_ROLES.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
      }
      if (!canAssignRole(actorRole, role)) {
        return res.status(403).json({ error: 'Forbidden' });
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
      const actorRole = await requireOrgAdmin(pool, res, req.params.orgId, userId);
      if (!actorRole) return;
      const { role } = req.body;
      if (!ASSIGNABLE_ROLES.includes(role)) {
        return res.status(400).json({ error: 'Invalid role' });
      }
      if (!canAssignRole(actorRole, role)) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        'UPDATE organization_users SET role = $1 WHERE organization_id = $2 AND user_id = $3 RETURNING *',
        [role, req.params.orgId, req.params.userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Member not found' });
      const row = result.rows[0];
      res.json({ ...row, role: normaliseRole(row.role) });
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
      if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
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
      if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
      const result = await pool.query(
        `SELECT p.*, o.name AS organization_name
         FROM pets p
         LEFT JOIN organizations o ON o.id = p.organization_id
         WHERE p.organization_id = $1
         ORDER BY p.created_at`,
        [req.params.orgId]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        name: r.name,
        species: r.species,
        breed: r.breed,
        organization_id: r.organization_id,
        organization_name: r.organization_name || null,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId } = req.params;
    const data = req.body || {};
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const id = data.id || uuidv4();
      const name = data.name;
      const species = data.species;
      if (!name || !species) {
        return res.status(400).json({ error: 'name and species are required' });
      }

      const dateOfBirth = normalizeCalendarDateInput(data.dateOfBirth || data.date_of_birth);
      const neuteredDate = normalizeCalendarDateInput(data.neuteredDate || data.neutered_date);
      const result = await pool.query(
        `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
          bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
          photo_path, vet_id, color_index, passed_away, organization_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
         RETURNING *`,
        [
          id,
          userId,
          name,
          species,
          data.breed || '',
          data.age ?? null,
          dateOfBirth,
          data.weight ?? null,
          data.gender || null,
          data.bio || '',
          data.insurance || '',
          neuteredDate,
          data.neuterDismissed ?? data.neuter_dismissed ?? false,
          data.chipId || data.chip_id || '',
          data.chipDismissed ?? data.chip_dismissed ?? false,
          data.photoPath || data.photo_path || null,
          data.vetId || data.vet_id || null,
          data.colorValue ?? data.color_index ?? null,
          data.passedAway ?? data.passed_away ?? false,
          orgId,
        ],
      );
      const row = result.rows[0];
      res.status(201).json({
        id: row.id,
        name: row.name,
        species: row.species,
        breed: row.breed || '',
        organization_id: row.organization_id,
        date_of_birth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets/:petId/transfer', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    const data = req.body || {};
    const recipientEmail = (data.recipient_email || data.recipientEmail || '').trim();
    const transferType = (data.transfer_type || data.transferType || 'adoption').trim();
    const notes = (data.notes || '').trim();

    if (!recipientEmail) {
      return res.status(400).json({ error: 'Recipient email is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const recipientResult = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [recipientEmail],
      );
      if (recipientResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const result = await transferOrgPetToUser(pool, {
        orgId,
        petId,
        adminId: userId,
        recipientId: recipientResult.rows[0].id,
        transferType,
        notes,
      });
      res.json(result);
    } catch (err) {
      if (err.statusCode === 404) return res.status(404).json({ error: err.message });
      if (err.statusCode === 400) return res.status(400).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/archived', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await requireOrgAdmin(pool, res, req.params.orgId, userId))) return;
      const result = await pool.query('SELECT * FROM archived_pets WHERE organization_id = $1 ORDER BY created_at DESC', [req.params.orgId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  function fosterParentToMap(row) {
    const displayName = (row.display_name || '').trim();
    let activePets = row.active_pets || [];
    if (typeof activePets === 'string') {
      try {
        activePets = JSON.parse(activePets);
      } catch (_) {
        activePets = [];
      }
    }
    return {
      id: row.id,
      kind: row.kind,
      user_id: row.user_id || null,
      display_name: displayName || row.email || '',
      email: row.email || null,
      phone: row.phone || null,
      notes: row.notes || '',
      role: row.role ? normaliseRole(row.role) : null,
      photo_url: row.photo_url || null,
      active_pet_count: parseInt(row.active_pet_count, 10) || 0,
      active_pets: activePets,
    };
  }

  router.get('/:orgId/foster-parents', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const memberResult = await pool.query(
        `SELECT ou.id,
                'member' AS kind,
                u.id AS user_id,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
                u.email,
                u.photo_url,
                ou.role,
                NULL::varchar AS phone,
                ''::text AS notes,
                (
                  SELECT COUNT(DISTINCT fpl.pet_id)::int
                  FROM foster_placements fpl
                  WHERE fpl.organization_id = ou.organization_id
                    AND fpl.foster_user_id = u.id
                    AND fpl.status = ANY($2::text[])
                ) AS active_pet_count,
                (
                  SELECT COALESCE(json_agg(json_build_object(
                    'pet_id', p.id,
                    'pet_name', p.name,
                    'status', fpl.status
                  ) ORDER BY p.name), '[]'::json)
                  FROM foster_placements fpl
                  JOIN pets p ON p.id = fpl.pet_id
                  WHERE fpl.organization_id = ou.organization_id
                    AND fpl.foster_user_id = u.id
                    AND fpl.status = ANY($2::text[])
                ) AS active_pets
         FROM organization_users ou
         JOIN users u ON u.id = ou.user_id
         WHERE ou.organization_id = $1
           AND ou.role IN (${fosterParentMemberRolesSql()})
         ORDER BY display_name, u.email`,
        [orgId, OPEN_PLACEMENT_STATUSES],
      );

      const externalResult = await pool.query(
        `SELECT fp.id,
                'external' AS kind,
                fp.user_id,
                fp.display_name,
                fp.email,
                NULL AS photo_url,
                NULL AS role,
                fp.phone,
                fp.notes,
                (
                  SELECT COUNT(DISTINCT fpl.pet_id)::int
                  FROM foster_placements fpl
                  WHERE fpl.organization_id = fp.organization_id
                    AND fpl.org_foster_parent_id = fp.id
                    AND fpl.status = ANY($2::text[])
                ) AS active_pet_count,
                (
                  SELECT COALESCE(json_agg(json_build_object(
                    'pet_id', p.id,
                    'pet_name', p.name,
                    'status', fpl.status
                  ) ORDER BY p.name), '[]'::json)
                  FROM foster_placements fpl
                  JOIN pets p ON p.id = fpl.pet_id
                  WHERE fpl.organization_id = fp.organization_id
                    AND fpl.org_foster_parent_id = fp.id
                    AND fpl.status = ANY($2::text[])
                ) AS active_pets
         FROM org_foster_parents fp
         WHERE fp.organization_id = $1
         ORDER BY fp.display_name`,
        [orgId, OPEN_PLACEMENT_STATUSES],
      );

      const combined = [
        ...memberResult.rows.map(fosterParentToMap),
        ...externalResult.rows.map(fosterParentToMap),
      ].sort((a, b) => a.display_name.localeCompare(b.display_name, undefined, { sensitivity: 'base' }));

      res.json(combined);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/foster-parents', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const data = req.body || {};
    const displayName = (data.display_name || data.displayName || '').trim();
    const email = (data.email || '').trim() || null;
    const phone = (data.phone || '').trim() || null;
    const notes = (data.notes || '').trim();

    if (!displayName) {
      return res.status(400).json({ error: 'Display name is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const id = uuidv4();
      const result = await pool.query(
        `INSERT INTO org_foster_parents (
           id, organization_id, display_name, email, phone, notes
         ) VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [id, orgId, displayName, email, phone, notes],
      );
      const row = result.rows[0];
      res.status(201).json(fosterParentToMap({
        ...row,
        kind: 'external',
        photo_url: null,
        role: null,
        active_pet_count: 0,
      }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:orgId/foster-parents/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const fosterParentId = req.params.id;
    const data = req.body || {};
    const displayName = (data.display_name || data.displayName || '').trim();
    const email = (data.email || '').trim() || null;
    const phone = (data.phone || '').trim() || null;
    const notes = (data.notes || '').trim();

    if (!displayName) {
      return res.status(400).json({ error: 'Display name is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        `UPDATE org_foster_parents
         SET display_name = $1, email = $2, phone = $3, notes = $4, updated_at = NOW()
         WHERE id = $5 AND organization_id = $6
         RETURNING *`,
        [displayName, email, phone, notes, fosterParentId, orgId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Foster parent not found' });
      }
      const row = result.rows[0];
      res.json(fosterParentToMap({
        ...row,
        kind: 'external',
        photo_url: null,
        role: null,
        active_pet_count: 0,
      }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:orgId/foster-parents/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    const fosterParentId = req.params.id;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const result = await pool.query(
        'DELETE FROM org_foster_parents WHERE id = $1 AND organization_id = $2 RETURNING id',
        [fosterParentId, orgId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Foster parent not found' });
      }
      res.json({ deleted: true, id: fosterParentId });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/placements', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const orgId = req.params.orgId;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const result = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.organization_id = $1
         ORDER BY fp.created_at DESC`,
        [orgId],
      );
      res.json(result.rows.map((row) => placementToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/pets/:petId/foster-history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const petResult = await pool.query(
        'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const result = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.organization_id = $1 AND fp.pet_id = $2
         ORDER BY fp.created_at DESC`,
        [orgId, petId],
      );
      res.json(result.rows.map((row) => placementToMap(row)));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:orgId/pets/:petId/placement', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;
      const petResult = await pool.query(
        'SELECT id FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const active = await getActivePlacementForPet(pool, petId);
      if (!active) {
        return res.json({ status: PLACEMENT_STATUS_NOT_IN_FOSTER, placement: null });
      }
      const detail = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.id = $1`,
        [active.id],
      );
      res.json({
        status: active.status,
        placement: placementToMap(detail.rows[0]),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets/:petId/placements', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    const data = req.body || {};
    const fosterUserId = data.foster_user_id || data.fosterUserId;
    const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
    const notes = (data.notes || '').trim();

    if (!fosterUserId) {
      return res.status(400).json({ error: 'Foster parent user is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const petResult = await pool.query(
        'SELECT id, name FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = petResult.rows[0];

      const fosterMember = await pool.query(
        'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
        [orgId, fosterUserId],
      );
      if (
        fosterMember.rows.length === 0
        || !isFosterParentMember(fosterMember.rows[0].role)
      ) {
        return res.status(400).json({ error: 'Selected user is not a foster parent for this organization' });
      }

      const existing = await getActivePlacementForPet(pool, petId);
      if (existing) {
        return res.status(409).json({ error: 'Pet already has an active foster placement' });
      }

      const id = uuidv4();
      const insertResult = await pool.query(
        `INSERT INTO foster_placements (
           id, organization_id, pet_id, foster_user_id, status, start_date, notes, created_by
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          id,
          orgId,
          petId,
          fosterUserId,
          PLACEMENT_STATUS_PENDING,
          startDate,
          notes,
          userId,
        ],
      );
      const placement = insertResult.rows[0];

      const adminResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const adminName = userDisplayName(adminResult.rows[0] || {});

      await createNotification(pool, {
        userId: fosterUserId,
        petId,
        petName: pet.name,
        title: 'Foster placement request',
        message: `${adminName} invited you to foster ${pet.name}.`,
        type: 'general',
      });

      const detail = await pool.query(
        `SELECT fp.*,
                p.name AS pet_name,
                p.species AS pet_species,
                o.name AS organization_name,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
                u.email AS foster_email
         FROM foster_placements fp
         JOIN pets p ON p.id = fp.pet_id
         JOIN organizations o ON o.id = fp.organization_id
         JOIN users u ON u.id = fp.foster_user_id
         WHERE fp.id = $1`,
        [placement.id],
      );

      res.status(201).json(placementToMap(detail.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/end', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
        [placementId, orgId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (![PLACEMENT_STATUS_PENDING, PLACEMENT_STATUS_IN_PROGRESS].includes(placement.status)) {
        return res.status(400).json({ error: 'Placement is not active' });
      }

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1,
             end_date = COALESCE($2, CURRENT_DATE),
             updated_at = NOW()
         WHERE id = $3
         RETURNING *`,
        [PLACEMENT_STATUS_NOT_IN_FOSTER, endDate, placementId],
      );

      if (placement.status === PLACEMENT_STATUS_IN_PROGRESS) {
        await revokeFosterPetAccess(pool, placement.pet_id, placement.foster_user_id);
      }

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Foster period ended',
        message: `The foster period for ${petName} has ended.`,
        type: 'general',
      });

      res.json(placementToMap(updateResult.rows[0], { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/start-adoption', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const adoptionConditions = (data.adoption_conditions || data.adoptionConditions || '').trim();

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
        [placementId, orgId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (placement.status !== PLACEMENT_STATUS_IN_PROGRESS) {
        return res.status(400).json({ error: 'Placement must be in progress to start adoption' });
      }

      const nextStatus = adoptionConditions
        ? PLACEMENT_STATUS_PENDING_CONDITIONS
        : PLACEMENT_STATUS_WAITING_ADOPTION;

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1,
             adoption_conditions = $2,
             updated_at = NOW()
         WHERE id = $3
         RETURNING *`,
        [nextStatus, adoptionConditions, placementId],
      );

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption ready to confirm',
        message: adoptionConditions
          ? `${petName} is ready for adoption once pre-adoption conditions are met.`
          : `Please confirm adoption of ${petName}.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updateResult.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/complete-conditions', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
        [placementId, orgId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (placement.status !== PLACEMENT_STATUS_PENDING_CONDITIONS) {
        return res.status(400).json({ error: 'Placement is not awaiting condition completion' });
      }

      const updateResult = await pool.query(
        `UPDATE foster_placements
         SET status = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING *`,
        [PLACEMENT_STATUS_WAITING_ADOPTION, placementId],
      );

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption ready to confirm',
        message: `Pre-adoption conditions for ${petName} are complete. Please confirm adoption.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updateResult.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/placements/:id/cancel-adoption', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, id: placementId } = req.params;
    const data = req.body || {};
    const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const placementResult = await pool.query(
        'SELECT * FROM foster_placements WHERE id = $1 AND organization_id = $2',
        [placementId, orgId],
      );
      if (placementResult.rows.length === 0) {
        return res.status(404).json({ error: 'Placement not found' });
      }
      const placement = placementResult.rows[0];
      if (![PLACEMENT_STATUS_WAITING_ADOPTION, PLACEMENT_STATUS_PENDING_CONDITIONS].includes(placement.status)) {
        return res.status(400).json({ error: 'Placement is not in an adoption step' });
      }

      const petResult = await pool.query(
        'SELECT name FROM pets WHERE id = $1',
        [placement.pet_id],
      );
      const petName = petResult.rows[0]?.name || 'Pet';

      const updated = await cancelAdoptionPlacement(pool, placement, endDate);

      await createNotification(pool, {
        userId: placement.foster_user_id,
        petId: placement.pet_id,
        petName,
        title: 'Adoption cancelled',
        message: `The adoption process for ${petName} was cancelled. The pet returns to organisation custody.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, placementId);
      res.json(placementToMap(detail || updated, { pet_name: petName }));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:orgId/pets/:petId/placements/direct-adopt', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { orgId, petId } = req.params;
    const data = req.body || {};
    const fosterUserId = data.foster_user_id || data.fosterUserId;
    const adoptionConditions = (data.adoption_conditions || data.adoptionConditions || '').trim();
    const notes = (data.notes || '').trim();

    if (!fosterUserId) {
      return res.status(400).json({ error: 'Foster parent user is required' });
    }

    try {
      if (!(await requireOrgAdmin(pool, res, orgId, userId))) return;

      const petResult = await pool.query(
        'SELECT id, name FROM pets WHERE id = $1 AND organization_id = $2',
        [petId, orgId],
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const pet = petResult.rows[0];

      const fosterMember = await pool.query(
        'SELECT role FROM organization_users WHERE organization_id = $1 AND user_id = $2',
        [orgId, fosterUserId],
      );
      if (
        fosterMember.rows.length === 0
        || !isFosterParentMember(fosterMember.rows[0].role)
      ) {
        return res.status(400).json({ error: 'Selected user is not a foster parent for this organization' });
      }

      const existing = await getActivePlacementForPet(pool, petId);
      if (existing) {
        return res.status(409).json({ error: 'Pet already has an active foster placement' });
      }

      const placementId = uuidv4();
      const nextStatus = adoptionConditions
        ? PLACEMENT_STATUS_PENDING_CONDITIONS
        : PLACEMENT_STATUS_WAITING_ADOPTION;

      const insertResult = await pool.query(
        `INSERT INTO foster_placements (
           id, organization_id, pet_id, foster_user_id, status, notes,
           adoption_conditions, created_by
         ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [
          placementId,
          orgId,
          petId,
          fosterUserId,
          nextStatus,
          notes,
          adoptionConditions,
          userId,
        ],
      );

      const adminResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const adminName = userDisplayName(adminResult.rows[0] || {});

      await createNotification(pool, {
        userId: fosterUserId,
        petId,
        petName: pet.name,
        title: 'Adoption ready to confirm',
        message: adoptionConditions
          ? `${adminName} invited you to adopt ${pet.name}. Pre-adoption conditions apply.`
          : `${adminName} invited you to adopt ${pet.name}. Please confirm to complete adoption.`,
        type: 'general',
      });

      const detail = await loadPlacementDetail(pool, insertResult.rows[0].id);
      res.status(201).json(placementToMap(detail || insertResult.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}

// Exported for tests.
export { getMemberRole, requireOrgAdmin, requireSuperAdmin };
