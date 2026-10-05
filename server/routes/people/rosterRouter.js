import express from 'express';

import { publicError } from '../../config/security.js';
import { extractUserId } from '../../lib/requireAuth.js';
import { asPeopleError, buildRoster } from '../../lib/people/index.js';

function sendPeopleError(res, err) {
  const pe = asPeopleError(err);
  if (pe) return res.status(pe.status).json(pe.toJson());
  return null;
}

export default function rosterRouter(pool) {
  const router = express.Router();

  router.get('/', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });
    try {
      const includeInactive = req.query.include_inactive === 'true'
        || req.query.includeInactive === 'true';
      const roster = await buildRoster(pool, userId, { includeInactive });
      res.json(roster);
    } catch (err) {
      if (sendPeopleError(res, err)) return;
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
