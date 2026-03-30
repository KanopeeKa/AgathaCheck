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

export default function weightEntriesRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id;
      let result;
      if (petId) {
        result = await pool.query('SELECT * FROM weight_entries WHERE pet_id = $1 AND user_id = $2 ORDER BY measured_at DESC', [petId, userId]);
      } else {
        result = await pool.query('SELECT * FROM weight_entries WHERE user_id = $1 ORDER BY measured_at DESC', [userId]);
      }
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/latest', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id;
      const result = await pool.query(
        'SELECT * FROM weight_entries WHERE pet_id = $1 AND user_id = $2 ORDER BY measured_at DESC LIMIT 1',
        [petId, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'No weight entries found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { pet_id, weight, unit = 'kg', measured_at } = req.body;
      const id = uuidv4();
      const result = await pool.query(
        'INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, measured_at) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [id, pet_id, userId, weight, unit, measured_at || new Date().toISOString()]
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
      const { weight, unit, measured_at } = req.body;
      const result = await pool.query(
        'UPDATE weight_entries SET weight = $1, unit = $2, measured_at = $3 WHERE id = $4 AND user_id = $5 RETURNING *',
        [weight, unit, measured_at, req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Weight entry not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('DELETE FROM weight_entries WHERE id = $1 AND user_id = $2 RETURNING *', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Weight entry not found' });
      res.json({ message: 'Weight entry deleted' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
}
