import { Router } from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { publicError } from '../../config/security.js';
import { requireAuth } from '../../lib/requireAuth.js';
import { resolveSupportScreenshotFile } from '../../lib/support/screenshots/storage.js';
import { userIsSupportStaff } from '../../lib/support/staff/staffFlag.js';

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUuid(value) {
  return typeof value === 'string' && UUID_RE.test(value);
}

export default function supportAttachmentsRoutes(pool) {
  const router = Router();
  router.use(createApiLimiter());
  router.use(requireAuth);

  router.get('/:id', async (req, res) => {
    try {
      const isStaff = await userIsSupportStaff(pool, req.userId);
      if (isStaff === null) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      if (!isStaff) {
        return res.status(403).json({ error: 'Forbidden' });
      }

      const attachmentId = req.params.id;
      if (!isValidUuid(attachmentId)) {
        return res.status(400).json({ error: 'Invalid attachment id' });
      }

      const result = await pool.query(
        `SELECT storage_key, mime
         FROM support_attachments
         WHERE id = $1`,
        [attachmentId],
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Not found' });
      }

      const row = result.rows[0];
      const resolved = resolveSupportScreenshotFile(row.storage_key);
      if (!resolved) {
        return res.status(404).json({ error: 'Not found' });
      }

      const mimeType = row.mime || resolved.mime;
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'private, no-store');
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.sendFile(resolved.filePath, (err) => {
        if (err && !res.headersSent) {
          res.status(404).json({ error: 'Not found' });
        }
      });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
