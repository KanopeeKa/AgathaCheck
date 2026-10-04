import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import {
  extractUserId,
  handleDocumentUpload,
  insertHealthEventPhoto,
  removeHealthDocumentFromDisk,
} from './shared.js';

export function registerDocumentsRoutes(router, pool) {
  async function canManageHealthDocuments(pool, entryId, userId) {
    const row = await pool.query(
      'SELECT pet_id FROM health_entries WHERE id = $1 LIMIT 1',
      [entryId],
    );
    const petId = row.rows[0]?.pet_id;
    if (!petId) return false;
    return hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_DOCUMENTS_MANAGE);
  }

  router.get('/:id/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const occurrenceId =
        req.query.occurrence_id || req.query.health_occurrence_id || null;
      const params = [req.params.id];
      let sql =
        'SELECT * FROM health_event_photos WHERE health_entry_id = $1';
      if (occurrenceId) {
        sql += ' AND health_occurrence_id = $2';
        params.push(occurrenceId);
      }
      sql += ' ORDER BY created_at';
      const result = await pool.query(sql, params);
      res.json(result.rows.map(r => ({
        id: r.id,
        health_entry_id: r.health_entry_id,
        health_occurrence_id: r.health_occurrence_id || null,
        url: r.url,
        created_at: r.created_at,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/photos', handleDocumentUpload, async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const entryRow = await pool.query(
        'SELECT pet_id FROM health_entries WHERE id = $1',
        [req.params.id],
      );
      const body = req.body || {};
      const occurrenceId =
        body.health_occurrence_id || body.healthOccurrenceId || null;
      if (occurrenceId) {
        const occ = await pool.query(
          `SELECT id FROM health_occurrences
           WHERE id = $1 AND health_entry_id = $2`,
          [occurrenceId, req.params.id],
        );
        if (occ.rows.length === 0) {
          return res.status(400).json({ error: 'Invalid occurrence for entry' });
        }
      }
      const id = uuidv4();
      const row = await insertHealthEventPhoto(pool, {
        photoId: id,
        entryId: req.params.id,
        occurrenceId,
        file: req.file,
        bodyUrl: req.body?.url,
      });
      recordPetActivityForPet(pool, {
        petId: entryRow.rows[0]?.pet_id,
        actorUserId: userId,
        eventType: 'document_upload',
        metadata: { document_count: 1 },
      });
      res.status(201).json(row);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:entryId/photos/:photoId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.entryId, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const existing = await pool.query(
        'SELECT url FROM health_event_photos WHERE id = $1 AND health_entry_id = $2',
        [req.params.photoId, req.params.entryId]
      );
      await pool.query(
        'DELETE FROM health_event_photos WHERE id = $1 AND health_entry_id = $2',
        [req.params.photoId, req.params.entryId]
      );
      if (existing.rows[0]?.url) {
        removeHealthDocumentFromDisk(existing.rows[0].url);
      }
      res.json({ deleted: true });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });
}
