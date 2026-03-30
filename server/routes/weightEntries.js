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
        result = await pool.query(
          'SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = $1 AND we.pet_id = $2 ORDER BY we.date DESC',
          [userId, petId]
        );
      } else {
        result = await pool.query(
          'SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = $1 ORDER BY we.date DESC',
          [userId]
        );
      }
      res.json(result.rows.map(weightEntryToMap));
    } catch (err) {
      res.status(500).json({ error: err.message });
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
      const result = await pool.query(
        'SELECT we.*, p.name as pet_name FROM weight_entries we JOIN pets p ON we.pet_id = p.id WHERE p.user_id = $1 AND we.pet_id = $2 ORDER BY we.date DESC LIMIT 1',
        [userId, petId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'No weight entries found' });
      res.json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      const dateVal = data.date || data.measured_at || new Date().toISOString();
      const weightVal = typeof data.weight === 'number' ? data.weight : parseFloat(data.weight || '0');
      const result = await pool.query(
        'INSERT INTO weight_entries (id, pet_id, weight, unit, date, notes) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [id, petId, weightVal, data.unit || 'kg', dateVal, data.notes || '']
      );
      res.status(201).json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const dateVal = data.date || data.measured_at || new Date().toISOString();
      const weightVal = typeof data.weight === 'number' ? data.weight : parseFloat(data.weight || '0');
      const result = await pool.query(
        'UPDATE weight_entries SET weight = $1, unit = $2, date = $3, notes = $4 WHERE id = $5 AND user_id = $6 RETURNING *',
        [weightVal, data.unit || 'kg', dateVal, data.notes || '', req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      res.json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('DELETE FROM weight_entries WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
}
