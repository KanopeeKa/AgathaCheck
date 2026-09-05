import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { userCanManageHealthEntry } from '../../lib/petAccess.js';
import { recordPetActivityForPet } from '../../lib/petActivity.js';
import { buildHealthFileApiPath } from '../../lib/privateHealthStorage.js';
import {
  extractUserId,
  handleDocumentUpload,
  removeHealthDocumentFromDisk,
  saveHealthDocument,
} from './shared.js';

export function registerDocumentsRoutes(router, pool) {
  router.get('/:id/photos', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const result = await pool.query(
        'SELECT * FROM health_event_photos WHERE health_entry_id = $1 ORDER BY created_at',
        [req.params.id]
      );
      res.json(result.rows.map(r => ({
        id: r.id,
        health_entry_id: r.health_entry_id,
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
      if (!(await userCanManageHealthEntry(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Entry not found' });
      }
      const entryRow = await pool.query(
        'SELECT pet_id FROM health_entries WHERE id = $1',
        [req.params.id],
      );
      const id = uuidv4();
      const url = req.file
        ? saveHealthDocument(req.file, id)
        : req.body?.url || buildHealthFileApiPath(id);
      const result = await pool.query(
        'INSERT INTO health_event_photos (id, health_entry_id, url) VALUES ($1, $2, $3) RETURNING *',
        [id, req.params.id, url]
      );
      recordPetActivityForPet(pool, {
        petId: entryRow.rows[0]?.pet_id,
        actorUserId: userId,
        eventType: 'document_upload',
        metadata: { document_count: 1 },
      });
      res.status(201).json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:entryId/photos/:photoId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await userCanManageHealthEntry(pool, req.params.entryId, userId))) {
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
