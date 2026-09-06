import { Router } from 'express';

import { publicError } from '../config/security.js';
import { hasPetCapability, PET_CAPABILITIES } from '../lib/petCapabilityPolicy.js';
import { resolvePrivateHealthFile } from '../lib/privateHealthStorage.js';
import { extractUserId } from './healthEntries/shared.js';

async function lookupHealthFilePetId(pool, fileId) {
  const issueDoc = await pool.query(
    `SELECT hi.pet_id
     FROM health_issue_documents hid
     JOIN health_issues hi ON hi.id = hid.health_issue_id
     WHERE hid.id = $1
     LIMIT 1`,
    [fileId]
  );
  if (issueDoc.rows[0]?.pet_id) return issueDoc.rows[0].pet_id;

  const entryPhoto = await pool.query(
    `SELECT he.pet_id
     FROM health_event_photos hep
     JOIN health_entries he ON he.id = hep.health_entry_id
     WHERE hep.id = $1
     LIMIT 1`,
    [fileId]
  );
  return entryPhoto.rows[0]?.pet_id || null;
}

export default function healthFilesRoutes(pool) {
  const router = Router();

  router.get('/:id', async (req, res) => {
    const userId = extractUserId(req);
    if (!userId) return res.status(401).json({ error: 'Unauthorized' });

    try {
      const petId = await lookupHealthFilePetId(pool, req.params.id);
      if (!petId || !(await hasPetCapability(pool, userId, petId, PET_CAPABILITIES.HEALTH_VIEW))) {
        return res.status(404).json({ error: 'Not found' });
      }

      const resolved = resolvePrivateHealthFile(req.params.id);
      if (!resolved) {
        return res.status(404).json({ error: 'Not found' });
      }

      res.setHeader('Content-Type', resolved.mimeType);
      res.setHeader('Cache-Control', 'private, no-store');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.sendFile(resolved.filePath, (err) => {
        if (err && !res.headersSent) {
          res.status(404).json({ error: 'Not found' });
        }
      });
    } catch (err) {
      res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
