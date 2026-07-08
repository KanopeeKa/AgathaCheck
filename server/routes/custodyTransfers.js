import express from 'express';
import jwt from 'jsonwebtoken';

import { createApiLimiter } from '../config/rateLimit.js';
import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import {
  acceptCustodyTransfer,
  cancelCustodyTransfer,
} from '../lib/custodyTransfers.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

export default function custodyTransfersRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT ct.*, p.name AS pet_name
         FROM custody_transfers ct
         JOIN pets p ON p.id = ct.pet_id
         WHERE ct.status = 'pending'
           AND (
             ct.to_user_id = $1
             OR ct.to_org_id IN (
               SELECT organization_id FROM organization_users
               WHERE user_id = $1 AND role IN ('super_admin', 'admin')
             )
           )
         ORDER BY ct.created_at DESC`,
        [userId],
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await acceptCustodyTransfer(client, req.params.id, userId);
      await client.query('COMMIT');
      res.json(result);
    } catch (err) {
      await client.query('ROLLBACK');
      if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    } finally {
      client.release();
    }
  });

  router.post('/:id/cancel', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const reason = (req.body?.reason || '').trim();
    try {
      const result = await cancelCustodyTransfer(pool, req.params.id, userId, reason);
      res.json(result);
    } catch (err) {
      if (err.statusCode) return res.status(err.statusCode).json({ error: err.message });
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
