import express from 'express';
import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { createApiLimiter } from '../config/rateLimit.js';
import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import { createNotification, userDisplayName } from '../lib/notificationHelper.js';
import {
  isShareLinkExpired,
  normalizeShareExpiryDays,
  shareExpiryFromNow,
} from '../lib/shareLinkPolicy.js';
import { buildSharePreviewResponse } from '../lib/sharePreview.js';
import { userCanSharePet, userOwnsPet } from '../lib/petAccess.js';

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

function shareLinkBlockedResponse(link) {
  if (link.status === 'revoked') {
    return { status: 410, error: 'Share link is no longer valid' };
  }
  if (isShareLinkExpired(link.expires_at)) {
    return { status: 410, error: 'Share link has expired' };
  }
  return null;
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
  router.use(createApiLimiter());

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.body?.pet_id || req.body?.petId;
    if (!petId) return res.status(400).json({ error: 'pet_id is required' });
    try {
      if (!(await userCanSharePet(pool, petId, userId))) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      let code;
      let linkId;
      let inserted = false;
      const expiresInDays = normalizeShareExpiryDays(
        req.body?.expires_in_days ?? req.body?.expiresInDays
      );
      const expiresAt = shareExpiryFromNow(expiresInDays);
      for (let attempt = 0; attempt < 5 && !inserted; attempt++) {
        code = generateShareCode();
        linkId = uuidv4();
        try {
          await pool.query(
            `INSERT INTO pet_share_links (id, pet_id, code, created_by, status, expires_at)
             VALUES ($1, $2, $3, $4, 'pending', $5)`,
            [linkId, petId, code, userId, expiresAt]
          );
          inserted = true;
        } catch (err) {
          if (err.code !== '23505') throw err;
        }
      }
      if (!inserted) {
        return res.status(500).json({ error: 'Could not generate share code' });
      }
      res.status(201).json({
        share_code: code,
        link_id: linkId,
        expires_at: expiresAt.toISOString(),
        expires_in_days: expiresInDays,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/links/:linkId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `DELETE FROM pet_share_links sl
         USING pets p
         WHERE sl.id = $1 AND sl.pet_id = p.id
           AND sl.status IN ('pending', 'active', 'revoked')
           AND (
             p.user_id = $2
             OR (
               sl.created_by = $2
               AND EXISTS (
                 SELECT 1 FROM pet_access pa
                 INNER JOIN foster_placements fp
                   ON fp.pet_id = pa.pet_id AND fp.foster_user_id = pa.user_id
                 WHERE pa.pet_id = p.id AND pa.user_id = $2
                   AND pa.role = 'foster'
                   AND fp.status = 'in_progress'
                   AND COALESCE(pa.hidden, false) = false
               )
             )
           )
         RETURNING sl.id, sl.status`,
        [req.params.linkId, userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Share link not found' });
      }
      res.json({ message: 'Share link deleted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/pending', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    // Link-based sharing is one-step; no pending queue.
    res.json([]);
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

  router.post('/pending/:petId/accept', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    return res.status(410).json({ error: 'Pending share flow is no longer used; accept via the share link instead' });
  });

  router.post('/pending/:petId/decline', (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    return res.status(410).json({ error: 'Pending share flow is no longer used' });
  });

  router.put('/:petId/hide', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { hidden } = req.body;
      const accessResult = await pool.query(
        `SELECT role FROM pet_access
         WHERE pet_id = $1 AND user_id = $2 AND role IN ('shared', 'foster')
         LIMIT 1`,
        [req.params.petId, userId],
      );
      if (accessResult.rows.length === 0) {
        return res.status(403).json({ error: 'Only shared or fostered pets can be hidden' });
      }
      const role = accessResult.rows[0].role;
      await pool.query(
        'UPDATE pet_access SET hidden = $1 WHERE pet_id = $2 AND user_id = $3 AND role = $4',
        [hidden, req.params.petId, userId, role],
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
      const blocked = shareLinkBlockedResponse(link);
      if (blocked) {
        return res.status(blocked.status).json({ error: blocked.error });
      }

      const petResult = await pool.query('SELECT * FROM pets WHERE id = $1', [link.pet_id]);
      if (petResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pet not found' });
      }
      const petRow = petResult.rows[0];

      const ownerResult = await pool.query(
        'SELECT first_name FROM users WHERE id = $1',
        [petRow.user_id]
      );
      const owner = ownerResult.rows[0] || {};

      res.json(buildSharePreviewResponse(link, petRow, owner));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:code/accept', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { code } = req.params;
    if (code === 'pending' || code === 'hidden' || code === 'links') {
      return res.status(404).json({ error: 'Not found' });
    }
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const linkResult = await client.query(
        `SELECT sl.*, p.user_id as owner_id, p.name as pet_name
         FROM pet_share_links sl
         JOIN pets p ON p.id = sl.pet_id
         WHERE sl.code = $1
         FOR UPDATE OF sl`,
        [code]
      );
      const link = linkResult.rows[0];
      if (!link) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Share link not found or expired' });
      }
      const blocked = shareLinkBlockedResponse(link);
      if (blocked) {
        await client.query('ROLLBACK');
        return res.status(blocked.status).json({ error: blocked.error });
      }
      if (link.owner_id === userId) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'You already own this pet' });
      }

      const existing = await client.query(
        'SELECT role FROM pet_access WHERE pet_id = $1 AND user_id = $2',
        [link.pet_id, userId]
      );
      if (existing.rows.length > 0) {
        await client.query('COMMIT');
        const role = existing.rows[0].role;
        return res.json({
          pet_id: link.pet_id,
          status: role === 'shared' || role === 'guardian' ? 'shared' : role,
        });
      }

      if (link.status === 'active') {
        if (link.claimed_by === userId) {
          await client.query('COMMIT');
          return res.json({ pet_id: link.pet_id, status: 'shared' });
        }
        await client.query('ROLLBACK');
        return res.status(410).json({ error: 'This share link has already been used' });
      }

      const accessId = uuidv4();
      await client.query(
        `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by, share_link_id)
         VALUES ($1, $2, $3, 'shared', $4, $5)`,
        [accessId, link.pet_id, userId, link.created_by, link.id]
      );

      await client.query(
        `UPDATE pet_share_links
         SET status = 'active', claimed_by = $1, claimed_at = NOW()
         WHERE id = $2`,
        [userId, link.id]
      );

      const accepterResult = await client.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId]
      );
      const accepterName = userDisplayName(accepterResult.rows[0] || {});

      await createNotification(client, {
        userId: link.owner_id,
        petId: link.pet_id,
        petName: link.pet_name,
        title: 'Share accepted',
        message: `${accepterName} is now following ${link.pet_name}. You can remove them at any time from the Sharing section.`,
        type: 'general',
      });

      await client.query('COMMIT');
      res.json({ pet_id: link.pet_id, status: 'shared' });
    } catch (err) {
      await client.query('ROLLBACK');
      if (err.code === '23505') {
        return res.status(409).json({ error: 'You already have access to this pet' });
      }
      res.status(500).json({ error: publicError(err) });
    } finally {
      client.release();
    }
  });

  return router;
}
