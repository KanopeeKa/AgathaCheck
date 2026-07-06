import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { userCanManagePet } from '../../lib/petAccess.js';
import { extractUserId } from './shared.js';

export function registerFamilyEventsRoutes(router, pool) {
  function familyEventToMap(row) {
    return {
      id: row.id,
      pet_id: row.pet_id,
      organization_id: row.organization_id,
      user_id: row.user_id,
      event_type: row.event_type || 'placement',
      assigned_to_user_id: row.assigned_to_user_id || null,
      assigned_name: row.assigned_name?.trim() || '',
      assigned_email: row.assigned_email || '',
      from_date: row.from_date ? dateToIsoDate(row.from_date) : null,
      to_date: row.to_date ? dateToIsoDate(row.to_date) : null,
      notes: row.notes || '',
      created_by: row.created_by || null,
      created_at: row.created_at,
      updated_at: row.updated_at,
      marked_at: row.marked_at || null,
    };
  }

  async function userCanManagePetFamilyEvents(pool, petId, userId) {
    return userCanManagePet(pool, petId, userId);
  }

  router.get('/:id/family-events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT fe.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS assigned_name,
          u.email AS assigned_email
         FROM family_events fe
         LEFT JOIN users u ON u.id = fe.assigned_to_user_id
         WHERE fe.pet_id = $1
         ORDER BY fe.from_date DESC NULLS LAST, fe.created_at DESC`,
        [petId]
      );
      res.status(200).json(result.rows.map(familyEventToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/family-events', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const pet = await pool.query('SELECT organization_id FROM pets WHERE id = $1', [petId]);
      const orgId = pet.rows[0]?.organization_id;
      if (!orgId) return res.status(400).json({ error: 'Pet is not in an organization' });
      const data = req.body || {};
      const fromDate = normalizeCalendarDateInput(data.from_date || data.fromDate);
      const toDate = normalizeCalendarDateInput(data.to_date || data.toDate);
      if (!fromDate && !toDate) {
        return res.status(400).json({ error: 'Due date or completed on date is required' });
      }
      const id = data.id || uuidv4();
      const result = await pool.query(
        `INSERT INTO family_events (id, user_id, pet_id, organization_id, event_type, assigned_to_user_id,
          from_date, to_date, notes, created_by, marked_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *`,
        [
          id, userId, petId, orgId,
          data.event_type || data.eventType || 'placement',
          data.assigned_to_user_id || data.assignedToUserId || null,
          fromDate, toDate,
          data.notes || '',
          userId,
          toDate ? new Date() : null,
        ]
      );
      if (toDate) {
        const histId = uuidv4();
        await pool.query(
          `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, notes)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [histId, id, fromDate, toDate, userId, data.notes || '']
        );
      }
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      if (row.assigned_to_user_id) {
        const u = await pool.query(
          `SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) AS name, email FROM users WHERE id = $1`,
          [row.assigned_to_user_id]
        );
        if (u.rows[0]) {
          row.assigned_name = u.rows[0].name;
          row.assigned_email = u.rows[0].email;
        }
      }
      res.status(201).json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.put('/:id/family-events/:eventId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const data = req.body || {};
      const fromDate = data.from_date !== undefined || data.fromDate !== undefined
        ? normalizeCalendarDateInput(data.from_date || data.fromDate)
        : undefined;
      const toDate = data.to_date !== undefined || data.toDate !== undefined
        ? normalizeCalendarDateInput(data.to_date || data.toDate)
        : undefined;
      const existing = await pool.query(
        'SELECT * FROM family_events WHERE id = $1 AND pet_id = $2',
        [eventId, petId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      const prev = existing.rows[0];
      const newFrom = fromDate !== undefined ? fromDate : dateToIsoDate(prev.from_date);
      const newTo = toDate !== undefined ? toDate : dateToIsoDate(prev.to_date);
      if (!newFrom && !newTo) {
        return res.status(400).json({ error: 'Due date or completed on date is required' });
      }
      const newlyCompleted = !prev.to_date && newTo;
      const result = await pool.query(
        `UPDATE family_events SET assigned_to_user_id = $1, from_date = $2, to_date = $3,
          notes = $4, updated_at = NOW(), marked_at = CASE WHEN $5 THEN NOW() ELSE marked_at END
         WHERE id = $6 AND pet_id = $7 RETURNING *`,
        [
          data.assigned_to_user_id ?? data.assignedToUserId ?? prev.assigned_to_user_id,
          newFrom, newTo,
          data.notes ?? prev.notes,
          newlyCompleted,
          eventId, petId,
        ]
      );
      if (newlyCompleted) {
        const histId = uuidv4();
        await pool.query(
          `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, notes)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [histId, eventId, newFrom, newTo, userId, data.notes || '']
        );
      }
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      if (row.assigned_to_user_id) {
        const u = await pool.query(
          `SELECT TRIM(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) AS name, email FROM users WHERE id = $1`,
          [row.assigned_to_user_id]
        );
        if (u.rows[0]) {
          row.assigned_name = u.rows[0].name;
          row.assigned_email = u.rows[0].email;
        }
      }
      res.json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/family-events/:eventId/mark-complete', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const data = req.body || {};
      const completedOn = normalizeCalendarDateInput(
        data.completed_on || data.completedOn || data.to_date || data.toDate,
      );
      if (!completedOn) {
        return res.status(400).json({ error: 'Completed on date is required' });
      }
      const existing = await pool.query(
        'SELECT * FROM family_events WHERE id = $1 AND pet_id = $2',
        [eventId, petId]
      );
      if (existing.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      const prev = existing.rows[0];
      const markedAt = new Date();
      const result = await pool.query(
        `UPDATE family_events SET to_date = $1, marked_at = $2, updated_at = NOW()
         WHERE id = $3 AND pet_id = $4 RETURNING *`,
        [completedOn, markedAt, eventId, petId]
      );
      const histId = uuidv4();
      await pool.query(
        `INSERT INTO family_event_history (id, family_event_id, due_date, completed_on, marked_by_user_id, marked_at, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [histId, eventId, dateToIsoDate(prev.from_date), completedOn, userId, markedAt, data.notes || '']
      );
      const row = result.rows[0];
      row.assigned_name = '';
      row.assigned_email = '';
      res.json(familyEventToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/family-events/:eventId/history', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        `SELECT feh.*,
          TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS marked_by_name
         FROM family_event_history feh
         LEFT JOIN users u ON u.id = feh.marked_by_user_id
         WHERE feh.family_event_id = $1 AND feh.status = 'completed'
         ORDER BY feh.marked_at DESC`,
        [eventId]
      );
      res.json(result.rows.map((r) => ({
        id: r.id,
        family_event_id: r.family_event_id,
        due_date: r.due_date ? dateToIsoDate(r.due_date) : null,
        completed_on: r.completed_on ? dateToIsoDate(r.completed_on) : null,
        marked_at: r.marked_at,
        marked_by_user_id: r.marked_by_user_id,
        marked_by_name: r.marked_by_name?.trim() || null,
        notes: r.notes || '',
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id/family-events/:eventId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const { id: petId, eventId } = req.params;
    try {
      if (!(await userCanManagePetFamilyEvents(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      const result = await pool.query(
        'DELETE FROM family_events WHERE id = $1 AND pet_id = $2 RETURNING id',
        [eventId, petId]
      );
      if (result.rows.length === 0) return res.status(404).json({ error: 'Event not found' });
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
