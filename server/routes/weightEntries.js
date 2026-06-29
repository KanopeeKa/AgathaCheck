import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import {
  accessiblePetSql,
  userCanManagePet,
  userCanManageWeightEntry,
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

function weightEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    pet_name: row.pet_name || null,
    weight: row.weight,
    unit: row.unit || 'kg',
    date: row.date ? row.date.toISOString?.() || String(row.date) : null,
    notes: row.notes || '',
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}

export default function weightEntriesRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        if (!(await userCanManagePet(pool, petId, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          `SELECT we.*, p.name as pet_name FROM weight_entries we
           JOIN pets p ON we.pet_id = p.id
           WHERE we.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
           ORDER BY we.date DESC`,
          [petId, userId]
        );
      } else {
        result = await pool.query(
          `SELECT we.*, p.name as pet_name FROM weight_entries we
           JOIN pets p ON we.pet_id = p.id
           WHERE ${accessiblePetSql('p', '$1')}
           ORDER BY we.date DESC`,
          [userId]
        );
      }
      res.json(result.rows.map(weightEntryToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/latest', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      if (!petId) {
        return res.status(400).json({ error: 'pet_id is required' });
      }
      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT we.*, p.name as pet_name FROM weight_entries we
         JOIN pets p ON we.pet_id = p.id
         WHERE we.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
         ORDER BY we.date DESC LIMIT 1`,
        [petId, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'No weight entries found' });
      res.json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const dateVal = data.date || data.measured_at || new Date().toISOString();
      const weightVal = typeof data.weight === 'number' ? data.weight : parseFloat(data.weight || '0');
      const result = await pool.query(
        'INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
        [id, petId, userId, weightVal, data.unit || 'kg', dateVal, data.notes || '']
      );
      res.status(201).json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const data = req.body;
      const dateVal = data.date || data.measured_at || new Date().toISOString();
      const weightVal = typeof data.weight === 'number' ? data.weight : parseFloat(data.weight || '0');
      const result = await pool.query(
        'UPDATE weight_entries SET weight = $1, unit = $2, date = $3, notes = $4 WHERE id = $5 RETURNING *',
        [weightVal, data.unit || 'kg', dateVal, data.notes || '', req.params.id]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      res.json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      await pool.query('DELETE FROM weight_entries WHERE id = $1', [req.params.id]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
