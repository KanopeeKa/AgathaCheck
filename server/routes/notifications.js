import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { createApiLimiter } from '../config/rateLimit.js';
import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import {
  buildNotificationDeepLink,
  checkDueNotifications,
} from '../lib/checkDueNotifications.js';
import {
  normaliseKind,
  normalisePriority,
} from '../lib/notificationKind.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

function notificationToMap(row) {
  const petId = row.pet_id || null;
  const healthEntryId = row.health_entry_id || null;
  return {
    id: row.id,
    user_id: row.user_id,
    pet_id: petId,
    pet_name: row.pet_name || null,
    health_entry_id: healthEntryId,
    deep_link: buildNotificationDeepLink(petId, healthEntryId),
    organization_id: row.organization_id || null,
    title: row.title || '',
    message: row.message || '',
    type: row.type || 'general',
    kind: normaliseKind(row.kind),
    priority: normalisePriority(row.priority),
    resolved_at: row.resolved_at
      ? row.resolved_at.toISOString?.() || String(row.resolved_at)
      : null,
    is_read: row.is_read ?? row.read ?? false,
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}

export default function notificationsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
      res.json(result.rows.map(notificationToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/unread-count', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND (is_read = false OR (is_read IS NULL AND read = false))',
        [userId]
      );
      res.json({ unread_count: parseInt(result.rows[0].count, 10) });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/read', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query(
        'UPDATE notifications SET is_read = true, read = true WHERE id = $1 AND user_id = $2',
        [req.params.id, userId]
      );
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/read', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query(
        'UPDATE notifications SET is_read = true, read = true WHERE id = $1 AND user_id = $2',
        [req.params.id, userId]
      );
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/read-all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('UPDATE notifications SET is_read = true, read = true WHERE user_id = $1', [userId]);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/read-all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('UPDATE notifications SET is_read = true, read = true WHERE user_id = $1', [userId]);
      res.json({ success: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/preferences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM notification_preferences WHERE user_id = $1', [userId]);
      const prefs = {};
      for (const row of result.rows) {
        prefs[row.preference] = row.value;
      }
      res.json(prefs);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/preferences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      for (const [preference, value] of Object.entries(data)) {
        const existing = await pool.query(
          'SELECT id FROM notification_preferences WHERE user_id = $1 AND preference = $2',
          [userId, preference]
        );
        if (existing.rows.length > 0) {
          await pool.query(
            'UPDATE notification_preferences SET value = $1 WHERE user_id = $2 AND preference = $3',
            [String(value), userId, preference]
          );
        } else {
          const id = uuidv4();
          await pool.query(
            'INSERT INTO notification_preferences (id, user_id, preference, value) VALUES ($1, $2, $3, $4)',
            [id, userId, preference, String(value)]
          );
        }
      }
      res.json(data);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/check-due', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petNames = req.body?.pet_names || req.body?.petNames || {};
      const result = await checkDueNotifications(pool, userId, petNames);
      res.json(result);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
