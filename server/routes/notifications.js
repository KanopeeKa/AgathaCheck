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

export default function notificationsRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/unread-count', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND read = false', [userId]);
      res.json({ count: parseInt(result.rows[0].count, 10) });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/:id/read', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2', [req.params.id, userId]);
      res.json({ message: 'Marked as read' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/read-all', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await pool.query('UPDATE notifications SET read = true WHERE user_id = $1', [userId]);
      res.json({ message: 'All marked as read' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/preferences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('SELECT * FROM notification_preferences WHERE user_id = $1', [userId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.put('/preferences', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const prefs = req.body;
      for (const [preference, value] of Object.entries(prefs)) {
        const existing = await pool.query('SELECT id FROM notification_preferences WHERE user_id = $1 AND preference = $2', [userId, preference]);
        if (existing.rows.length > 0) {
          await pool.query('UPDATE notification_preferences SET value = $1 WHERE user_id = $2 AND preference = $3', [String(value), userId, preference]);
        } else {
          const id = uuidv4();
          await pool.query('INSERT INTO notification_preferences (id, user_id, preference, value) VALUES ($1, $2, $3, $4)', [id, userId, preference, String(value)]);
        }
      }
      const result = await pool.query('SELECT * FROM notification_preferences WHERE user_id = $1', [userId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/check-due', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    res.json({ checked: true, due: [] });
  });

  return router;
}
