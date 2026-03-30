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

export default function sharingRoutes(pool) {
  const router = express.Router();

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { pet_id } = req.body;
      const code = uuidv4().substring(0, 8);
      res.status(201).json({ code, pet_id });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        "SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p ON p.id = pa.pet_id WHERE pa.user_id = $1 AND pa.role = 'pending_shared'",
        [userId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
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
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/pending/:petId/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { organization_id } = req.body || {};
      await pool.query(
        "UPDATE pet_access SET role = 'shared' WHERE pet_id = $1 AND user_id = $2 AND role = 'pending_shared'",
        [req.params.petId, userId]
      );
      res.json({ message: 'Share accepted' });
    } catch (err) {
      res.status(500).json({ error: err.message });
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
      res.status(500).json({ error: err.message });
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
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:code', async (req, res) => {
    res.json({ code: req.params.code, pet: null });
  });

  router.post('/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.json({ message: 'Share accepted' });
  });

  return router;
}
