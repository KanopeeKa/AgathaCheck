import express from 'express';
import { v4 as uuidv4 } from 'uuid';

import { createApiLimiter } from '../config/rateLimit.js';
import { publicError } from '../config/security.js';
import { logAuditEventSafe } from '../lib/audit.js';
import { extractUserId } from '../lib/requireAuth.js';
import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../lib/calendarDate.js';
import { refreshPetWeightCache } from '../lib/petWeightSync.js';
import {
  accessiblePetSql,
  userCanManageWeightEntry,
} from '../lib/petAccess.js';
import { hasPetCapability, PET_CAPABILITIES } from '../lib/petCapabilityPolicy.js';

function weightEntryToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    pet_name: row.pet_name || null,
    weight: row.weight,
    unit: row.unit || 'kg',
    date: row.date ? dateToIsoDate(row.date) : null,
    notes: row.notes || '',
    created_at: row.created_at ? row.created_at.toISOString?.() || String(row.created_at) : null,
  };
}

function parseWeightInput(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return { error: 'weight is required' };
  }
  const weightVal = typeof raw === 'number' ? raw : parseFloat(String(raw));
  if (!Number.isFinite(weightVal)) {
    return { error: 'weight must be a number' };
  }
  if (weightVal <= 0) {
    return { error: 'weight must be positive' };
  }
  return { value: weightVal };
}

export default function weightEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      let result;
      if (petId) {
        if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_VIEW))) {
          return res.status(403).json({ error: 'Forbidden' });
        }
        result = await pool.query(
          `SELECT we.*, p.name as pet_name FROM weight_entries we
           JOIN pets p ON we.pet_id = p.id
           WHERE we.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
           ORDER BY we.date DESC, we.created_at DESC`,
          [petId, userId]
        );
      } else {
        result = await pool.query(
          `SELECT we.*, p.name as pet_name FROM weight_entries we
           JOIN pets p ON we.pet_id = p.id
           WHERE ${accessiblePetSql('p', '$1')}
           ORDER BY we.date DESC, we.created_at DESC`,
          [userId]
        );
      }
      res.json(result.rows.map(weightEntryToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/latest', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const petId = req.query.pet_id || req.query.petId;
      if (!petId) {
        return res.status(400).json({ error: 'pet_id is required' });
      }
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_VIEW))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT we.*, p.name as pet_name FROM weight_entries we
         JOIN pets p ON we.pet_id = p.id
         WHERE we.pet_id = $1 AND ${accessiblePetSql('p', '$2')}
         ORDER BY we.date DESC, we.created_at DESC LIMIT 1`,
        [petId, userId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'No weight entries found' });
      res.json(weightEntryToMap(result.rows[0]));
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
      if (!(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.WEIGHT_EDIT))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const dateVal = normalizeCalendarDateInput(data.date || data.measured_at)
        || todayCalendarIso();
      const parsedWeight = parseWeightInput(data.weight);
      if (parsedWeight.error) {
        return res.status(400).json({ error: parsedWeight.error });
      }
      const weightVal = parsedWeight.value;
      const result = await pool.query(
        'INSERT INTO weight_entries (id, pet_id, user_id, weight, unit, date, notes) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *',
        [id, petId, userId, weightVal, data.unit || 'kg', dateVal, data.notes || '']
      );
      await refreshPetWeightCache(pool, petId);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.created',
        resourceType: 'weight_entry',
        resourceId: id,
        petId,
        metadata: { weight: weightVal, unit: data.unit || 'kg' },
        req,
      });
      res.status(201).json(weightEntryToMap(result.rows[0]));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const data = req.body;
      const dateVal = normalizeCalendarDateInput(data.date || data.measured_at)
        || todayCalendarIso();
      const parsedWeight = parseWeightInput(data.weight);
      if (parsedWeight.error) {
        return res.status(400).json({ error: parsedWeight.error });
      }
      const weightVal = parsedWeight.value;
      const result = await pool.query(
        'UPDATE weight_entries SET weight = $1, unit = $2, date = $3, notes = $4 WHERE id = $5 RETURNING *',
        [weightVal, data.unit || 'kg', dateVal, data.notes || '', req.params.id]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Not found' });
      const row = result.rows[0];
      await refreshPetWeightCache(pool, row.pet_id);
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.updated',
        resourceType: 'weight_entry',
        resourceId: req.params.id,
        petId: row.pet_id,
        metadata: { weight: weightVal, unit: data.unit || 'kg' },
        req,
      });
      res.json(weightEntryToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageWeightEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const existing = await pool.query(
        'SELECT pet_id FROM weight_entries WHERE id = $1',
        [req.params.id],
      );
      await pool.query('DELETE FROM weight_entries WHERE id = $1', [req.params.id]);
      const petId = existing.rows[0]?.pet_id;
      if (petId) {
        await refreshPetWeightCache(pool, petId);
      }
      logAuditEventSafe(pool, {
        actorUserId: userId,
        action: 'weight_entry.deleted',
        resourceType: 'weight_entry',
        resourceId: req.params.id,
        petId: petId || null,
        req,
      });
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
