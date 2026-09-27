import express from 'express';

import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { ensurePersonalDirectory } from '../../lib/people/directory.js';
import { contactRowToMap, listContactsInDirectory, loadContactForViewer } from '../../lib/people/contactMapping.js';
import { createPersonalContact, patchPersonalContact } from '../../lib/people/contactMutations.js';

export default function contactsRouter(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const directoryId = await ensurePersonalDirectory(pool, userId);
      const includeInactive = req.query.include_inactive === 'true'
        || req.query.includeInactive === 'true';
      const rows = await listContactsInDirectory(pool, directoryId, userId, includeInactive);
      res.json(rows.map(contactRowToMap));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await createPersonalContact(pool, userId, req.body || {});
      if (result.error) return res.status(400).json({ error: result.error });
      res.status(201).json(contactRowToMap(result.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await loadContactForViewer(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Contact not found' });
      res.json(contactRowToMap(row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await patchPersonalContact(pool, req.params.id, userId, req.body || {});
      if (result.notFound) return res.status(404).json({ error: 'Contact not found' });
      if (result.error) return res.status(400).json({ error: result.error });
      res.json(contactRowToMap(result.row));
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await loadContactForViewer(pool, req.params.id, userId);
      if (!row) return res.status(404).json({ error: 'Contact not found' });
      if (row.legacy_vet_id) {
        return res.status(400).json({ error: 'Delete the linked vet record instead' });
      }
      const inUse = await pool.query(
        'SELECT 1 FROM pet_contact_relationships WHERE contact_id = $1 LIMIT 1',
        [req.params.id],
      );
      if (inUse.rows.length > 0) {
        return res.status(409).json({ error: 'Contact is linked to a pet relationship' });
      }
      await pool.query('DELETE FROM people_contacts WHERE id = $1', [req.params.id]);
      res.json({ message: 'Contact deleted' });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
