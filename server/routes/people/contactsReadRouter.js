import express from 'express';

import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import {
  asPeopleError,
  contactDetail,
  contactIdByLegacyVet,
  relatedCare,
} from '../../lib/people/index.js';

function sendPeopleError(res, err) {
  const pe = asPeopleError(err);
  if (pe) return res.status(pe.status).json(pe.toJson());
  return null;
}

/**
 * Mounted on /contacts before /:id CRUD routes (legacy-vet + related).
 */
export default function contactsReadRouter(pool) {
  const router = express.Router();

  router.get('/by-legacy-vet/:vetId', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await contactIdByLegacyVet(pool, userId, req.params.vetId);
      if (!result) {
        return res.status(404).json({ error: 'Contact not found', code: 'contact_not_found' });
      }
      res.json(result);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id/related', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await relatedCare(pool, userId, req.params.id);
      if (!result) {
        return res.status(404).json({ error: 'Contact not found', code: 'contact_not_found' });
      }
      res.json(result);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const result = await contactDetail(pool, userId, req.params.id);
      if (!result) {
        return res.status(404).json({ error: 'Contact not found', code: 'contact_not_found' });
      }
      res.json(result);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
