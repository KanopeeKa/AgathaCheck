import express from 'express';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { createNotification, userDisplayName } from '../lib/notificationHelper.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

function generateShareCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
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
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    age: row.age,
    dateOfBirth: row.date_of_birth ? row.date_of_birth.toISOString?.() || String(row.date_of_birth) : null,
    date_of_birth: row.date_of_birth ? row.date_of_birth.toISOString?.() || String(row.date_of_birth) : null,
    weight: row.weight,
    gender: row.gender,
    bio: row.bio || '',
    insurance: row.insurance || '',
    neuteredDate: row.neutered_date ? row.neutered_date.toISOString?.() || String(row.neutered_date) : null,
    neuterDismissed: row.neuter_dismissed || false,
    chipId: row.chip_id || '',
    chipDismissed: row.chip_dismissed || false,
    photoPath: row.photo_path,
    vetId: row.vet_id ? String(row.vet_id) : null,
    colorValue: resolveColorValue(row.color_index),
    passedAway: row.passed_away || false,
    organization_id: row.organization_id,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function vetRowToMap(row) {
  return {
    id: row.id,
    name: row.name,
    clinic: row.clinic,
    phone: row.phone,
    email: row.email,
    website: row.website || '',
    address: row.address || '',
    notes: row.notes || '',
  };
}

function healthEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    name: row.name || '',
    type: row.type,
    dosage: row.dosage || '',
    frequency: row.frequency || 'once',
    start_date: row.start_date ? row.start_date.toISOString?.() || String(row.start_date) : null,
    next_due_date: row.next_due_date ? row.next_due_date.toISOString?.() || String(row.next_due_date) : null,
    notes: row.notes || '',
    status: row.status || 'active',
  };
}

async function loadShareLink(pool, code) {
  const result = await pool.query(
    `SELECT sl.*, p.user_id as owner_id
     FROM pet_share_links sl
     JOIN pets p ON p.id = sl.pet_id
     WHERE sl.code = $1`,
    [code]
  );
  return result.rows[0] || null;
}

export default function sharingRoutes(pool) {
  const router = express.Router();

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.body?.pet_id || req.body?.petId;
    if (!petId) return res.status(400).json({ error: 'pet_id is required' });
    try {
      const petResult = await pool.query(
        'SELECT id FROM pets WHERE id = $1 AND user_id = $2',
        [petId, userId]
      );
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      let code;
      let inserted = false;
      for (let attempt = 0; attempt < 5 && !inserted; attempt++) {
        code = generateShareCode();
        try {
          await pool.query(
            'INSERT INTO pet_share_links (id, pet_id, code, created_by) VALUES ($1, $2, $3, $4)',
            [uuidv4(), petId, code, userId]
          );
          inserted = true;
        } catch (err) {
          if (err.code !== '23505') throw err;
        }
      }
      if (!inserted) {
        return res.status(500).json({ error: 'Could not generate share code' });
      }
      res.status(201).json({ share_code: code });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT pa.*, p.name as pet_name, p.species as pet_species, p.breed as pet_breed,
                p.photo_path as pet_photo_path, p.color_index as pet_color_value,
                TRIM(COALESCE(owner.first_name, '') || ' ' || COALESCE(owner.last_name, '')) as guardian_name
         FROM pet_access pa
         JOIN pets p ON p.id = pa.pet_id
         JOIN users owner ON owner.id = p.user_id
         WHERE pa.user_id = $1 AND pa.role = 'pending_shared'`,
        [userId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/hidden', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p ON p.id = pa.pet_id WHERE pa.user_id = $1 AND pa.hidden = true',
        [userId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/pending/:petId/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const accessResult = await pool.query(
        `SELECT pa.*, p.name as pet_name, p.user_id as owner_id
         FROM pet_access pa
         JOIN pets p ON p.id = pa.pet_id
         WHERE pa.pet_id = $1 AND pa.user_id = $2 AND pa.role = 'pending_shared'`,
        [req.params.petId, userId]
      );
      if (accessResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pending share not found' });
      }
      const access = accessResult.rows[0];

      await pool.query(
        "UPDATE pet_access SET role = 'shared', updated_at = NOW() WHERE pet_id = $1 AND user_id = $2 AND role = 'pending_shared'",
        [req.params.petId, userId]
      );

      const accepterResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId]
      );
      const accepterName = userDisplayName(accepterResult.rows[0] || {});

      await createNotification(pool, {
        userId: access.owner_id,
        petId: access.pet_id,
        petName: access.pet_name,
        title: 'Share accepted',
        message: `${accepterName} has accepted the invitation to follow ${access.pet_name}. You can remove them at any time from the Sharing section.`,
        type: 'general',
      });

      res.json({ message: 'Share accepted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/pending/:petId/decline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query(
        "DELETE FROM pet_access WHERE pet_id = $1 AND user_id = $2 AND role = 'pending_shared'",
        [req.params.petId, userId]
      );
      res.json({ message: 'Share declined' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:petId/hide', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { hidden } = req.body;
      await pool.query(
        'UPDATE pet_access SET hidden = $1 WHERE pet_id = $2 AND user_id = $3',
        [hidden, req.params.petId, userId]
      );
      res.json({ message: hidden ? 'Pet hidden' : 'Pet unhidden' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:code', async (req, res) => {
    const { code } = req.params;
    if (code === 'pending' || code === 'hidden') {
      return res.status(404).json({ error: 'Not found' });
    }
    try {
      const link = await loadShareLink(pool, code);
      if (!link) {
        return res.status(404).json({ error: 'Share link not found or expired' });
      }

      const petResult = await pool.query('SELECT * FROM pets WHERE id = $1', [link.pet_id]);
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const petRow = petResult.rows[0];

      const ownerResult = await pool.query(
        'SELECT id, first_name, last_name, email, photo_url, bio, category FROM users WHERE id = $1',
        [petRow.user_id]
      );
      const owner = ownerResult.rows[0] || {};

      let vet = null;
      if (petRow.vet_id) {
        const vetResult = await pool.query('SELECT * FROM vets WHERE id = $1', [petRow.vet_id]);
        if (vetResult.rows.length > 0) {
          vet = vetRowToMap(vetResult.rows[0]);
        }
      }

      const healthResult = await pool.query(
        `SELECT * FROM health_entries WHERE pet_id = $1 ORDER BY next_due_date ASC NULLS LAST, created_at DESC`,
        [link.pet_id]
      );

      res.json({
        pet: petRowToMap(petRow),
        owner: {
          id: owner.id,
          first_name: owner.first_name || '',
          last_name: owner.last_name || '',
          email: owner.email || '',
          photo_url: owner.photo_url || '',
          bio: owner.bio || '',
          category: owner.category || 'pet_guardian',
        },
        vet,
        health_entries: healthResult.rows.map(healthEntryToMap),
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { code } = req.params;
    if (code === 'pending' || code === 'hidden') {
      return res.status(404).json({ error: 'Not found' });
    }
    try {
      const link = await loadShareLink(pool, code);
      if (!link) {
        return res.status(404).json({ error: 'Share link not found or expired' });
      }
      if (link.owner_id === userId) {
        return res.status(400).json({ error: 'You already own this pet' });
      }

      const petResult = await pool.query('SELECT name, user_id FROM pets WHERE id = $1', [link.pet_id]);
      const pet = petResult.rows[0];
      if (!pet) {
        return res.status(404).json({ error: 'Pet not found' });
      }

      const existing = await pool.query(
        'SELECT role FROM pet_access WHERE pet_id = $1 AND user_id = $2',
        [link.pet_id, userId]
      );

      if (existing.rows.length > 0) {
        const role = existing.rows[0].role;
        return res.json({ pet_id: link.pet_id, status: role === 'shared' ? 'shared' : 'pending' });
      }

      await pool.query(
        `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by)
         VALUES ($1, $2, $3, 'pending_shared', $4)`,
        [uuidv4(), link.pet_id, userId, link.created_by]
      );

      const ownerResult = await pool.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [pet.user_id]
      );
      const ownerName = userDisplayName(ownerResult.rows[0] || {});

      await createNotification(pool, {
        userId,
        petId: link.pet_id,
        petName: pet.name,
        title: 'Pet share invitation',
        message: `You have been invited to follow ${pet.name} by ${ownerName}. Open your pet list to accept or decline.`,
        type: 'general',
      });

      res.json({ pet_id: link.pet_id, status: 'pending' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
