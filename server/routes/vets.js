import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    const payload = jwt.verify(auth.substring(7), JWT_SECRET);
    return payload.id;
  } catch (_) {
    return null;
  }
}

export default function vetsRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM vets WHERE user_id = $1 ORDER BY name', [userId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM vets WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name, clinic, phone, email } = req.body;
      const id = uuidv4();
      const result = await pool.query(
        'INSERT INTO vets (id, user_id, name, clinic, phone, email) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
        [id, userId, name, clinic || null, phone || null, email || null]
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
      const { name, clinic, phone, email } = req.body;
      const result = await pool.query(
        'UPDATE vets SET name = $1, clinic = $2, phone = $3, email = $4, updated_at = NOW() WHERE id = $5 AND user_id = $6 RETURNING *',
        [name, clinic, phone, email, req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('DELETE FROM vets WHERE id = $1 AND user_id = $2 RETURNING *', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json({ message: 'Vet deleted', vet: result.rows[0] });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
}
