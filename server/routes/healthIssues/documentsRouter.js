import { v4 as uuidv4 } from 'uuid';

import { publicError } from '../../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../../lib/petCapabilityPolicy.js';
import { buildHealthFileApiPath } from '../../lib/privateHealthStorage.js';
import {
  handleDocumentUpload,
  removeHealthDocumentFromDisk,
  saveHealthDocument,
} from '../healthEntries/shared.js';
import { extractUserId } from './shared.js';

const MAX_DOCUMENTS_PER_ISSUE = 4;

export function registerDocumentsRoutes(router, pool) {
  async function canManageHealthDocuments(pool, issueId, userId) {
    const row = await pool.query(
      'SELECT pet_id FROM health_issues WHERE id = $1 LIMIT 1',
      [issueId],
    );
    const petId = row.rows[0]?.pet_id;
    if (!petId) return false;
    return hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_DOCUMENTS_MANAGE);
  }

  router.get('/:id/documents', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const result = await pool.query(
        'SELECT * FROM health_issue_documents WHERE health_issue_id = $1 ORDER BY created_at',
        [req.params.id]
      );
      res.json(result.rows.map((r) => ({
        id: r.id,
        health_issue_id: r.health_issue_id,
        url: r.url,
        created_at: r.created_at,
      })));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/:id/documents', handleDocumentUpload, async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const countResult = await pool.query(
        'SELECT COUNT(*)::int AS count FROM health_issue_documents WHERE health_issue_id = $1',
        [req.params.id]
      );
      if (countResult.rows[0].count >= MAX_DOCUMENTS_PER_ISSUE) {
        return res.status(400).json({ error: 'Maximum 4 documents per health issue' });
      }
      const id = uuidv4();
      const url = req.file
        ? saveHealthDocument(req.file, id)
        : req.body?.url || buildHealthFileApiPath(id);
      const result = await pool.query(
        'INSERT INTO health_issue_documents (id, health_issue_id, url) VALUES ($1, $2, $3) RETURNING *',
        [id, req.params.id, url]
      );
      res.status(201).json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:issueId/documents/:documentId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canManageHealthDocuments(pool, req.params.issueId, userId))) {
        return res.status(404).json({ error: 'Not found' });
      }
      const existing = await pool.query(
        'SELECT url FROM health_issue_documents WHERE id = $1 AND health_issue_id = $2',
        [req.params.documentId, req.params.issueId]
      );
      await pool.query(
        'DELETE FROM health_issue_documents WHERE id = $1 AND health_issue_id = $2',
        [req.params.documentId, req.params.issueId]
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
