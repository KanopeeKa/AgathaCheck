import express from 'express';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../config/jwtSecret.js';
import { publicError } from '../config/security.js';
import {
  accessiblePetSql,
  userCanManagePet,
  userCanManageHealthIssue,
} from '../lib/petAccess.js';

function extractUserId(req) {
  const auth = req.headers['authorization'] || req.headers['Authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return null;
  try {
    return jwt.verify(auth.substring(7), JWT_SECRET).id;
  } catch (_) {
    return null;
  }
}

function issueRowToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    pet_name: row.pet_name || null,
    title: row.name || '',
    description: row.notes || '',
    name: row.name || '',
    issue_type: row.issue_type,
    notes: row.notes || '',
    start_date: row.start_date ? row.start_date.toISOString?.() || String(row.start_date) : null,
    end_date: row.end_date ? row.end_date.toISOString?.() || String(row.end_date) : null,
    status: row.status || 'active',
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
    updated_at: row.updated_at ? row.updated_at.toISOString?.() || String(row.updated_at) : null,
  };
}

export default function healthIssuesRoutes(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        if (!(await userCanManagePet(pool, petId, userId))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          `SELECT hi.*, p.name as pet_name FROM health_issues hi
           JOIN pets p ON hi.pet_id = p.id
           WHERE hi.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
           ORDER BY hi.created_at DESC`,
          [petId, userId]
        );
      } else {
        result = await pool.query(
          `SELECT hi.*, p.name as pet_name FROM health_issues hi
           JOIN pets p ON hi.pet_id = p.id
           WHERE ${accessiblePetSql('p', '$1')}
           ORDER BY hi.created_at DESC`,
          [userId]
        );
      }
      res.json(result.rows.map(issueRowToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await pool.query(
        `SELECT hi.*, p.name as pet_name FROM health_issues hi
         JOIN pets p ON hi.pet_id = p.id
         WHERE hi.id = $1 AND ${accessiblePetSql('p', '$2')}`,
        [req.params.id, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      res.json(issueRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const data = req.body;
      const id = data.id || uuidv4();
      const petId = data.pet_id || data.petId;
      if (!(await userCanManagePet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const startDate = data.start_date || data.startDate || null;
      const endDate = data.end_date || data.endDate || null;
      const nameVal = data.title || data.name || '';
      const notesVal = data.description || data.notes || '';
      const result = await pool.query(
        'INSERT INTO health_issues (id, pet_id, user_id, name, issue_type, notes, start_date, end_date, status) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *',
        [
          id, petId, userId, nameVal,
          data.issue_type || data.issueType || 'other',
          notesVal, startDate, endDate,
          data.status || 'active',
        ]
      );
      res.status(201).json(issueRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthIssue(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const data = req.body;
      const startDate = data.start_date || data.startDate || null;
      const endDate = data.end_date || data.endDate || null;
      const nameVal = data.title || data.name || '';
      const notesVal = data.description || data.notes || '';
      const result = await pool.query(
        'UPDATE health_issues SET name = $1, issue_type = $2, notes = $3, start_date = $4, end_date = $5, status = $6, updated_at = NOW() WHERE id = $7 RETURNING *',
        [
          nameVal,
          data.issue_type || data.issueType || 'other',
          notesVal, startDate, endDate,
          data.status || 'active',
          req.params.id,
        ]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      res.json(issueRowToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthIssue(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      await pool.query('DELETE FROM health_issues WHERE id = $1', [req.params.id]);
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:issueId/events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthIssue(pool, req.params.issueId, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const result = await pool.query(
        'SELECT * FROM health_issue_events WHERE health_issue_id = $1 ORDER BY created_at DESC',
        [req.params.issueId]
      );
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:issueId/events/:entryId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthIssue(pool, req.params.issueId, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      await pool.query(
        'DELETE FROM health_issue_events WHERE id = $1 AND health_issue_id = $2',
        [req.params.entryId, req.params.issueId]
      );
      res.json({ message: 'Event deleted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
