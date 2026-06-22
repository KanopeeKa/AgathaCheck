import express from 'express';
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

export default function sharingRoutes(pool) {
  const router = express.Router();

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    // NOT IMPLEMENTED: share-by-code has no persistence (there is no table that
    // maps a generated code to a pet), so a code returned here could never be
    // resolved. Return 501 instead of faking success — the working sharing flow
    // is the pending/hidden pet_access path below. The DB-backed access list,
    // role updates, and removals still live as stubs in routes/pets.js.
    return res.status(501).json({ error: 'Not implemented' });
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
      const { organization_id } = req.body || {};
      await pool.query(
        "UPDATE pet_access SET role = 'shared' WHERE pet_id = $1 AND user_id = $2 AND role = 'pending_shared'",
        [req.params.petId, userId]
      );
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
    // NOT IMPLEMENTED: see POST / above — no share-code persistence to look up.
    return res.status(501).json({ error: 'Not implemented' });
  });

  router.post('/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    // NOT IMPLEMENTED: share-by-code acceptance (see POST / above).
    return res.status(501).json({ error: 'Not implemented' });
  });

  return router;
}
