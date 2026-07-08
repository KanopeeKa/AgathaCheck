import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { createApiLimiter } from '../config/rateLimit.js';
import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';

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

function vetRowToMap(row) {
  return {
    id: row.id,
    user_id: row.user_id,
    name: row.name,
    clinic: row.clinic,
    phone: row.phone,
    email: row.email,
    website: row.website || '',
    address: row.address || '',
    notes: row.notes || '',
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export default function vetsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM vets WHERE user_id = $1 ORDER BY name', [userId]);
      res.json(result.rows.map(vetRowToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM vets WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json(vetRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name, clinic, phone, email, website, address, notes } = req.body;
      const id = uuidv4();
      const result = await pool.query(
        'INSERT INTO vets (id, user_id, name, clinic, phone, email, website, address, notes) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *',
        [id, userId, name, clinic || null, phone || null, email || null, website || '', address || '', notes || '']
      );
      res.status(201).json(vetRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { name, clinic, phone, email, website, address, notes } = req.body;
      const result = await pool.query(
        'UPDATE vets SET name = $1, clinic = $2, phone = $3, email = $4, website = $5, address = $6, notes = $7, updated_at = NOW() WHERE id = $8 AND user_id = $9 RETURNING *',
        [name, clinic, phone, email, website || '', address || '', notes || '', req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json(vetRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('DELETE FROM vets WHERE id = $1 AND user_id = $2 RETURNING *', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Vet not found' });
      res.json({ message: 'Vet deleted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
