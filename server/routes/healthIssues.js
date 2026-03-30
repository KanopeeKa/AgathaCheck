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

export default function healthIssuesRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id;
      let result;
      if (petId) {
        result = await pool.query('SELECT * FROM health_issues WHERE pet_id = $1 AND user_id = $2 ORDER BY created_at DESC', [petId, userId]);
      } else {
        result = await pool.query('SELECT * FROM health_issues WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
      }
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const { pet_id, issue_type, notes = '' } = req.body;
      const id = uuidv4();
      const result = await pool.query(
        'INSERT INTO health_issues (id, pet_id, user_id, issue_type, notes) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [id, pet_id, userId, issue_type, notes]
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
      const { issue_type, notes } = req.body;
      const result = await pool.query(
        'UPDATE health_issues SET issue_type = $1, notes = $2, updated_at = NOW() WHERE id = $3 AND user_id = $4 RETURNING *',
        [issue_type, notes, req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Health issue not found' });
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query('DELETE FROM health_issues WHERE id = $1 AND user_id = $2 RETURNING *', [req.params.id, userId]);
      if (result.rows.length === 0) return res.status(404).json({ error: 'Health issue not found' });
      res.json({ message: 'Health issue deleted' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.get('/:issueId/events', async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM health_issue_events WHERE health_issue_id = $1 ORDER BY created_at DESC', [req.params.issueId]);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  router.delete('/:issueId/events/:entryId', async (req, res) => {
    try {
      await pool.query('DELETE FROM health_issue_events WHERE id = $1 AND health_issue_id = $2', [req.params.entryId, req.params.issueId]);
      res.json({ message: 'Event deleted' });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return router;
}
