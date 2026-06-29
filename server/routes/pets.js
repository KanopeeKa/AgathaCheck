import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { dateToIsoDate } from '../lib/calendarDate.js';
import { createNotification, userDisplayName } from '../lib/notificationHelper.js';
import {
  userCanAccessPet,
  userCanManagePet,
  userOwnsPet,
  COLLABORATOR_ROLES,
} from '../lib/petAccess.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

const PET_COLOR_PALETTE = [
  0xFF7E57C2, 0xFF9575CD, 0xFF5C6BC0, 0xFF7986CB, 0xFF4DB6AC,
  0xFF81C784, 0xFF4FC3F7, 0xFFBA68C8, 0xFFF06292, 0xFFE57373,
  0xFFFFB74D, 0xFFA1887F, 0xFF90A4AE, 0xFF64B5F6, 0xFFAED581,
];

function resolveColorValue(raw) {
  if (raw == null) return null;
  const v = typeof raw === 'number' ? raw : parseInt(raw, 10);
  if (isNaN(v)) return null;
  if (v < PET_COLOR_PALETTE.length) return PET_COLOR_PALETTE[v];
  return v;
}

function petRowToMap(row) {
  const isShared = row.is_shared === true || row.is_shared === 't';
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    age: row.age,
    dateOfBirth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
    date_of_birth: row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null,
    weight: row.weight,
    gender: row.gender,
    bio: row.bio || '',
    insurance: row.insurance || '',
    neuteredDate: row.neutered_date ? dateToIsoDate(row.neutered_date) : null,
    neuterDismissed: row.neuter_dismissed || false,
    chipId: row.chip_id || '',
    chipDismissed: row.chip_dismissed || false,
    photoPath: row.photo_path,
    vetId: row.vet_id ? String(row.vet_id) : null,
    colorValue: resolveColorValue(row.color_index),
    passedAway: row.passed_away || false,
    // Shared pets follow the owner's org in the DB, but the viewer should see
    // them under "My Pets", not the owner's organisation section.
    organization_id: isShared ? null : row.organization_id,
    is_shared: isShared,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

async function autoAssignColors(pool, pets) {
  const usedColors = new Set();
  for (const p of pets) {
    if (p.colorValue != null) usedColors.add(p.colorValue);
  }
  for (const p of pets) {
    if (p.colorValue == null) {
      let color = PET_COLOR_PALETTE[0];
      for (const c of PET_COLOR_PALETTE) {
        if (!usedColors.has(c)) {
          color = c;
          break;
        }
      }
      usedColors.add(color);
      p.colorValue = color;
      try {
        await pool.query('UPDATE pets SET color_index = $1 WHERE id = $2', [color, p.id]);
      } catch (_) {}
    }
  }
}

export default function petsRoutes(pool) {
  const router = express.Router();

  async function userInOrg(orgId, userId) {
    const result = await pool.query(
      'SELECT 1 FROM organization_users WHERE organization_id = $1 AND user_id = $2 LIMIT 1',
      [orgId, userId]
    );
    return result.rows.length > 0;
  }

  // NOT IMPLEMENTED: pet transfer to an org has no backing logic.
  router.post('/:id/transfer-to-org', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    return res.status(501).json({ error: 'Not implemented' });
  });

  // Family events (org foster/placement) — due = from_date, completed = to_date.
  function familyEventToMap(row) {
    return {
      id: row.id,
      pet_id: row.pet_id,
      organization_id: row.organization_id,
      user_id: row.user_id,
      event_type: row.event_type || 'placement',
      assigned_to_user_id: row.assigned_to_user_id || null,
      assigned_name: row.assigned_name?.trim() || '',
      assigned_email: row.assigned_email || '',
      from_date: row.from_date ? dateToIsoDate(row.from_date) : null,
      to_date: row.to_date ? dateToIsoDate(row.to_date) : null,
      notes: row.notes || '',
      created_by: row.created_by || null,
      created_at: row.created_at,
      updated_at: row.updated_at,
      marked_at: row.marked_at || null,
    };
  }

  async function userCanManagePetFamilyEvents(pool, petId, userId) {
    return userCanManagePet(pool, petId, userId);
  }

  router.get('/:id/family-events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT fe.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS assigned_name,
          u.email AS assigned_email
         FROM family_events fe
         LEFT JOIN users u ON u.id = fe.assigned_to_user_id
         WHERE fe.pet_id = $1
         ORDER BY fe.from_date DESC NULLS LAST, fe.created_at DESC`,
        [petId]
      );
      res.status(200).json(result.rows.map(familyEventToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/family-events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const pet = await pool.query('SELECT organization_id FROM pets WHERE id = $1', [petId]);
      const orgId = pet.rows[0]?.organization_id;
      if (!orgId) return res.status(400).json({ error: 'Pet is not in an organization' });
      const data = req.body || {};
      const fromDate = data.from_date || data.fromDate || null;
      const toDate = data.to_date || data.toDate || null;
      if (!fromDate && !toDate) {
        return res.status(400).json({ error: 'Due date or completed on date is required' });
      }
      const id = data.id || uuidv4();
      const result = await pool.query(
        `INSERT INTO family_events (id, user_id, pet_id, organization_id, event_type, assigned_to_user_id,
          from_date, to_date, notes, created_by, marked_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
        [
          id, userId, petId, orgId,
          data.event_type || data.eventType || 'placement',
          data.assigned_to_user_id || data.assignedToUserId || null,
          fromDate, toDate,
          data.notes || '',
          userId,
          toDate ? new Date() : null,
        ]
      );
      if (toDate) {
        const histId = uuidv4();
        await pool.query(
          `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, notes)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [histId, id, fromDate, toDate, userId, data.notes || '']
        );
      }
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      if (row.assigned_to_user_id) {
        const u = await pool.query(
          `SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) AS name, email FROM users WHERE id = $1`,
          [row.assigned_to_user_id]
        );
        if (u.rows[0]) {
          row.assigned_name = u.rows[0].name;
          row.assigned_email = u.rows[0].email;
        }
      }
      res.status(201).json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/family-events/:eventId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const data = req.body || {};
      const fromDate = data.from_date || data.fromDate;
      const toDate = data.to_date || data.toDate;
      const existing = await pool.query(
        'SELECT * FROM family_events WHERE id = $1 AND pet_id = $2',
        [eventId, petId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      const prev = existing.rows[0];
      const newFrom = fromDate !== undefined ? fromDate : prev.from_date;
      const newTo = toDate !== undefined ? toDate : prev.to_date;
      if (!newFrom && !newTo) {
        return res.status(400).json({ error: 'Due date or completed on date is required' });
      }
      const newlyCompleted = !prev.to_date && newTo;
      const result = await pool.query(
        `UPDATE family_events SET assigned_to_user_id = $1, from_date = $2, to_date = $3,
          notes = $4, updated_at = NOW(), marked_at = CASE WHEN $5 THEN NOW() ELSE marked_at END
         WHERE id = $6 AND pet_id = $7 RETURNING *`,
        [
          data.assigned_to_user_id ?? data.assignedToUserId ?? prev.assigned_to_user_id,
          newFrom, newTo,
          data.notes ?? prev.notes,
          newlyCompleted,
          eventId, petId,
        ]
      );
      if (newlyCompleted) {
        const histId = uuidv4();
        await pool.query(
          `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, notes)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [histId, eventId, newFrom, newTo, userId, data.notes || '']
        );
      }
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      if (row.assigned_to_user_id) {
        const u = await pool.query(
          `SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) AS name, email FROM users WHERE id = $1`,
          [row.assigned_to_user_id]
        );
        if (u.rows[0]) {
          row.assigned_name = u.rows[0].name;
          row.assigned_email = u.rows[0].email;
        }
      }
      res.json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/family-events/:eventId/mark-complete', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const data = req.body || {};
      const completedOn = data.completed_on || data.completedOn || data.to_date || data.toDate;
      if (!completedOn) {
        return res.status(400).json({ error: 'Completed on date is required' });
      }
      const existing = await pool.query(
        'SELECT * FROM family_events WHERE id = $1 AND pet_id = $2',
        [eventId, petId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      const prev = existing.rows[0];
      const markedAt = new Date();
      const result = await pool.query(
        `UPDATE family_events SET to_date = $1, marked_at = $2, updated_at = NOW()
         WHERE id = $3 AND pet_id = $4 RETURNING *`,
        [completedOn, markedAt, eventId, petId]
      );
      const histId = uuidv4();
      await pool.query(
        `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, marked_at, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [histId, eventId, prev.from_date, completedOn, userId, markedAt, data.notes || '']
      );
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      res.json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/family-events/:eventId/history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT feh.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM family_event_history feh
         LEFT JOIN users u ON u.id = feh.marked_by_user_id
         WHERE feh.family_event_id = $1 AND feh.status = 'completed'
         ORDER BY feh.marked_at DESC`,
        [eventId]
      );
      res.json(result.rows.map((r) => ({
        id: r.id,
        family_event_id: r.family_event_id,
        due_date: r.due_date ? String(r.due_date).split('T')[0] : null,
        completed_on: r.completed_on ? String(r.completed_on).split('T')[0] : null,
        marked_at: r.marked_at,
        marked_by_user_id: r.marked_by_user_id,
        marked_by_name: r.marked_by_name?.trim() || null,
        notes: r.notes || '',
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/family-events/:eventId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        'DELETE FROM family_events WHERE id = $1 AND pet_id = $2 RETURNING id',
        [eventId, petId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/share-links', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      if (!(await userOwnsPet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT sl.id, sl.code, sl.status, sl.created_at, sl.claimed_at,
                sl.claimed_by,
                TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) as claimed_by_name
         FROM pet_share_links sl
         LEFT JOIN users u ON u.id = sl.claimed_by
         WHERE sl.pet_id = $1
         ORDER BY sl.created_at DESC`,
        [id]
      );
      res.json(result.rows.map((row) => ({
        id: row.id,
        code: row.code,
        status: row.status || 'pending',
        created_at: row.created_at,
        claimed_at: row.claimed_at,
        claimed_by: row.claimed_by,
        claimed_by_name: row.claimed_by_name?.trim() || null,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/follow', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      const petResult = await pool.query('SELECT name, user_id FROM pets WHERE id = $1', [id]);
      const pet = petResult.rows[0];
      if (!pet) {
        return res.status(404).json({ error: 'Pet not found' });
      }

      const deleteResult = await pool.query(
        "DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role = 'shared' RETURNING id",
        [id, userId]
      );
      if (deleteResult.rows.length === 0) {
        return res.status(404).json({ error: 'Shared access not found' });
      }

      const followerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId]
      );
      const followerName = userDisplayName(followerResult.rows[0] || {});

      await createNotification(pool, {
        userId: pet.user_id,
        petId: id,
        petName: pet.name,
        title: 'Stopped following',
        message: `${followerName} stopped following ${pet.name}.`,
        type: 'general',
      });

      res.json({ message: 'Stopped following pet' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/access', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    try {
      if (!(await userOwnsPet(pool, id, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT pa.*,
                u.first_name, u.last_name, u.category, u.bio, u.photo_url
         FROM pet_access pa
         JOIN users u ON u.id = pa.user_id
         WHERE pa.pet_id = $1 AND pa.role IN ('shared', 'guardian')
         ORDER BY pa.created_at`,
        [id]
      );
      const access = result.rows.map((row) => ({
        id: row.id,
        pet_id: row.pet_id,
        user_id: row.user_id,
        role: row.role,
        invited_by: row.invited_by || null,
        created_at: row.created_at,
        user: {
          first_name: row.first_name || '',
          last_name: row.last_name || '',
          category: row.category || 'pet_guardian',
          bio: row.bio || '',
          photo_url: row.photo_url || '',
        },
      }));
      res.json(access);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/access/:userId/role', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    return res.status(501).json({ error: 'Not implemented' });
  });

  router.delete('/:id/access/:userId', async (req, res) => {
    const ownerId = extractUserId(req);
    if (!ownerId) return res.status(401).json({ error: 'Unauthorized' });
    const { id, userId: targetUserId } = req.params;
    try {
      if (!(await userOwnsPet(pool, id, ownerId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const petResult = await pool.query('SELECT name FROM pets WHERE id = $1', [id]);
      const petName = petResult.rows[0]?.name || 'the pet';

      const ownerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [ownerId]
      );
      const ownerName = userDisplayName(ownerResult.rows[0] || {});

      const deleteResult = await pool.query(
        "DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role IN ('shared', 'guardian', 'pending_shared') RETURNING id",
        [id, targetUserId]
      );
      if (deleteResult.rows.length === 0) {
        return res.status(404).json({ error: 'Access not found' });
      }

      await createNotification(pool, {
        userId: targetUserId,
        petId: id,
        petName,
        title: 'Sharing ended',
        message: `${ownerName} stopped sharing ${petName} with you.`,
        type: 'general',
      });

      res.json({ message: 'Access removed' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  // STUB: best-effort cascade cleanup of a pet's related data. Returns success
  // without deleting; the client calls it best-effort before DELETE /:id (which
  // relies on the schema's ON DELETE CASCADE for the actual cleanup).
  router.delete('/:id/data', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.status(200).json({ deleted: true, pet_id: req.params.id });
  });

  // STUB: the pet's passedAway flag is persisted via PUT /api/pets/:id; this
  // endpoint only exists to notify shared users (sharing is not implemented), so
  // it acknowledges without side effects.
  router.post('/:id/passed-away', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.status(200).json({ passed_away: true, pet_id: req.params.id });
  });

  router.get('/all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT p.*, false AS is_shared
         FROM pets p
         WHERE p.user_id = $1
         UNION ALL
         SELECT p.*, true AS is_shared
         FROM pets p
         JOIN pet_access pa ON pa.pet_id = p.id
         WHERE pa.user_id = $1 AND pa.role = ANY($2::text[]) AND COALESCE(pa.hidden, false) = false
         ORDER BY created_at`,
        [userId, COLLABORATOR_ROLES]
      );
      const pets = result.rows.map(petRowToMap);
      await autoAssignColors(pool, pets);
      res.json(pets);
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pets', `Error fetching pets: ${err.message}`) });
    }
  });

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT * FROM pets WHERE user_id = $1 ORDER BY created_at',
        [userId]
      );
      const pets = result.rows.map(petRowToMap);
      await autoAssignColors(pool, pets);
      res.json(pets);
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pets', `Error fetching pets: ${err.message}`) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(id)) {
      return res.status(400).json({ error: 'Invalid pet ID' });
    }
    try {
      if (!(await userCanAccessPet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const result = await pool.query(
        `SELECT p.*,
                CASE WHEN p.user_id = $2 THEN false ELSE true END AS is_shared
         FROM pets p
         WHERE p.id = $1`,
        [id, userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error fetching pet', `Error fetching pet: ${err.message}`) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const id = req.body.id || uuidv4();
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = req.body.dateOfBirth || req.body.date_of_birth || null;
      const neuteredDate = req.body.neuteredDate || null;
      if (organization_id && !(await userInOrg(organization_id, userId))) {
        return res.status(403).json({ error: 'Not a member of this organization' });
      }
      const result = await pool.query(
        `INSERT INTO pets (id, user_id, name, species, breed, age, date_of_birth, weight, gender,
          bio, insurance, neutered_date, neuter_dismissed, chip_id, chip_dismissed,
          photo_path, vet_id, color_index, passed_away, organization_id)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
         ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, species = EXCLUDED.species, breed = EXCLUDED.breed,
          age = EXCLUDED.age, date_of_birth = EXCLUDED.date_of_birth, weight = EXCLUDED.weight, gender = EXCLUDED.gender,
          bio = EXCLUDED.bio, insurance = EXCLUDED.insurance, neutered_date = EXCLUDED.neutered_date,
          neuter_dismissed = EXCLUDED.neuter_dismissed, chip_id = EXCLUDED.chip_id, chip_dismissed = EXCLUDED.chip_dismissed,
          photo_path = EXCLUDED.photo_path, vet_id = EXCLUDED.vet_id, color_index = EXCLUDED.color_index,
          passed_away = EXCLUDED.passed_away, organization_id = EXCLUDED.organization_id, updated_at = NOW()
         WHERE pets.user_id = $2 RETURNING *`,
        [id, userId, name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null]
      );
      res.status(201).json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error creating pet', `Error creating pet: ${err.message}`) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      if (!(await userCanManagePet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const {
        name, species, breed = '', age, weight, gender,
        bio = '', insurance = '',
        neuterDismissed = false, chipId = '', chipDismissed = false,
        photoPath, vetId, colorValue, passedAway = false,
        organization_id
      } = req.body;
      const dateOfBirth = req.body.dateOfBirth || req.body.date_of_birth || null;
      const neuteredDate = req.body.neuteredDate || null;
      const existingPet = await pool.query(
        'SELECT organization_id FROM pets WHERE id = $1',
        [id]
      );
      const previousOrgId = existingPet.rows[0]?.organization_id || null;
      const nextOrgId = organization_id || null;
      if (nextOrgId && String(nextOrgId) !== String(previousOrgId || '')
          && !(await userInOrg(nextOrgId, userId))) {
        return res.status(403).json({ error: 'Not a member of this organization' });
      }
      const result = await pool.query(
        `UPDATE pets SET name=$1, species=$2, breed=$3, age=$4, date_of_birth=$5, weight=$6, gender=$7,
          bio=$8, insurance=$9, neutered_date=$10, neuter_dismissed=$11, chip_id=$12, chip_dismissed=$13,
          photo_path=$14, vet_id=$15, color_index=$16, passed_away=$17, organization_id=$18,
          updated_at=NOW()
         WHERE id=$19 RETURNING *`,
        [name, species, breed, age, dateOfBirth, weight, gender,
         bio, insurance, neuteredDate, neuterDismissed, chipId, chipDismissed,
         photoPath || null, vetId || null, colorValue != null ? colorValue : null,
         passedAway, organization_id || null, id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      res.json(petRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error updating pet', `Error updating pet: ${err.message}`) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { id } = req.params;
      if (!(await userOwnsPet(pool, id, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      await pool.query('DELETE FROM pets WHERE id = $1 AND user_id = $2', [id, userId]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err, 'Error deleting pet', `Error deleting pet: ${err.message}`) });
    }
  });

  return router;
}
