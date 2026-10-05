import express from 'express';

import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  asPeopleError,
  canEditContact,
  contactRowToMap,
  createPersonalContact,
  deletePersonalContact,
  ensurePersonalDirectory,
  listContactSummaries,
  patchPersonalContact,
} from '../../lib/people/index.js';

function sendPeopleError(res, err) {
  const pe = asPeopleError(err);
  if (pe) return res.status(pe.status).json(pe.toJson());
  return null;
}

export default function contactsRouter(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await ensurePersonalDirectory(pool, userId);
      const includeInactive = req.query.include_inactive === 'true'
        || req.query.includeInactive === 'true';
      const summaries = await listContactSummaries(pool, userId, includeInactive);
      res.json(summaries);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.post('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const row = await createPersonalContact(pool, userId, req.body || {});
      res.status(201).json(contactRowToMap(row));
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.patch('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      if (!(await canEditContact(pool, req.params.id, userId))) {
        return res.status(404).json({ error: 'Contact not found', code: 'contact_not_found' });
      }
      const row = await patchPersonalContact(pool, req.params.id, userId, req.body || {});
      res.json(contactRowToMap(row));
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.delete('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      await deletePersonalContact(pool, req.params.id, userId);
      res.json({ message: 'Contact deleted' });
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
