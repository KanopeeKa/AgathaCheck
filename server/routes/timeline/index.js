import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { logAuditEventSafe } from '../../lib/audit.js';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { dateToIsoDate } from '../../lib/calendarDate.js';
import { buildPetTimeline } from '../../lib/timelineComposite.js';
import { userCanAccessPet } from '../../lib/petAccess.js';
import { extractUserId } from '../pets/shared.js';

export const AUDIT_PET_TIMELINE_ENTRY_CREATED = 'pet_timeline_entry_created';
export const AUDIT_PET_TIMELINE_ENTRY_UPDATED = 'pet_timeline_entry_updated';

export function registerTimelineRoutes(router, pool) {
  router.get('/:id/timeline', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    try {
      const timeline = await buildPetTimeline(pool, petId, userId);
      res.json(timeline);
    } catch (err) {
      if (err.statusCode === 403) return res.status(403).json({ error: 'Forbidden' });
      if (err.statusCode === 404) return res.status(404).json({ error: 'Pet not found' });
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/timeline/entries', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    const petId = req.params.id;
    const data = req.body || {};
    const title = (data.title || '').trim();
    const description = (data.description || '').trim();
    const startDate = normalizeCalendarDateInput(data.start_date || data.startDate);
    const endDate = normalizeCalendarDateInput(data.end_date || data.endDate);

    if (!title) {
      return res.status(400).json({ error: 'title is required' });
    }
    if (!startDate) {
      return res.status(400).json({ error: 'start_date is required' });
    }

    try {
      if (!(await userCanAccessPet(pool, petId, userId))) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const id = uuidv4();
      const result = await pool.query(
        `INSERT INTO pet_timeline_entries (
           id, pet_id, entry_type, title, description, start_date, end_date, created_by
         ) VALUES ($1, $2, 'manual', $3, $4, $5, $6, $7)
         RETURNING *`,
        [id, petId, title, description, startDate, endDate, userId],
      );
      const row = result.rows[0];

      await logAuditEventSafe(pool, {
        actorUserId: userId,
        action: AUDIT_PET_TIMELINE_ENTRY_CREATED,
        resourceType: 'pet_timeline_entry',
        resourceId: id,
        petId,
        req,
      });

      res.status(201).json({
        id: row.id,
        kind: 'manual',
        start_date: dateToIsoDate(row.start_date),
        end_date: row.end_date ? dateToIsoDate(row.end_date) : null,
        title: row.title,
        description: row.description,
        fillable: false,
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
