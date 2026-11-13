import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import multer from 'multer';

import { publicError } from '../../config/security.js';
import { createSupportTicket } from '../../lib/support/submit/createTicket.js';
import { resolveSupportSubmitAuth } from '../../lib/support/submit/authContext.js';
import { parseSupportTicketPayload } from '../../lib/support/submit/parseTicketPayload.js';
import { persistSupportScreenshotAttachments } from '../../lib/support/screenshots/persistForTicket.js';
import { removeSupportScreenshotFile } from '../../lib/support/screenshots/storage.js';
import {
  SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE,
  SUPPORT_SCREENSHOT_MAX_FILES,
} from '../../lib/support/screenshots/constants.js';
import { assertSupportScreenshotGate } from '../../lib/support/submit/screenshot_gate.js';
import { validateSupportTicketBody } from '../../lib/support/schema/validateTicketBody.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    files: SUPPORT_SCREENSHOT_MAX_FILES,
    fileSize: SUPPORT_SCREENSHOT_MAX_BYTES_PER_FILE,
  },
});

function shouldSkipSupportBackstop() {
  return process.env.NODE_ENV === 'test' || process.env.E2E === '1';
}

export default function supportTicketsRoutes(pool) {
  const router = Router();

  if (!shouldSkipSupportBackstop()) {
    router.use(
      rateLimit({
        windowMs: 60 * 1000,
        limit: 60,
        standardHeaders: 'draft-7',
        legacyHeaders: false,
        message: { error: 'Too many requests, please try again later.' },
      }),
    );
  }

  router.post('/tickets', (req, res, next) => {
    upload.any()(req, res, (err) => {
      if (!err) return next();
      if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ error: 'Each screenshot must be 2 MB or smaller.' });
      }
      if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_COUNT') {
        return res
          .status(400)
          .json({ error: `At most ${SUPPORT_SCREENSHOT_MAX_FILES} screenshots are allowed.` });
      }
      return res.status(400).json({ error: 'Invalid screenshot upload.' });
    });
  }, async (req, res) => {
    const auth = resolveSupportSubmitAuth(req);
    if (auth.status === 'invalid') {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    const screenshotGate = assertSupportScreenshotGate(req, auth);
    if (!screenshotGate.allowed) {
      return res.status(screenshotGate.status).json(screenshotGate.body);
    }

    const payload = parseSupportTicketPayload(req);
    if (!payload) {
      return res.status(400).json({ error: 'Invalid JSON body' });
    }

    const signedIn = auth.status === 'signed_in';
    const validated = validateSupportTicketBody(payload, { signedIn });
    if (!validated.ok) {
      return res.status(400).json({ error: 'Validation failed', details: validated.errors });
    }

    let accountEmail = null;
    if (signedIn) {
      try {
        const userRow = await pool.query('SELECT email FROM users WHERE id = $1', [auth.userId]);
        if (userRow.rows.length === 0) {
          return res.status(401).json({ error: 'Invalid or expired token' });
        }
        accountEmail = userRow.rows[0].email;
      } catch (err) {
        return res.status(500).json({ error: publicError(err) });
      }
    }

    const clientIp = req.ip || req.socket?.remoteAddress || '0.0.0.0';

    let attachments = [];
    if (screenshotGate.files.length > 0) {
      try {
        attachments = persistSupportScreenshotAttachments(screenshotGate.files);
      } catch (err) {
        const message = err?.message || 'Could not store screenshots.';
        return res.status(400).json({ error: message });
      }
    }

    try {
      const result = await createSupportTicket(pool, {
        signedIn,
        userId: signedIn ? auth.userId : null,
        accountEmail,
        body: validated.value,
        clientIp,
        attachments,
      });

      if (result.error === 'rate_limited') {
        res.setHeader('Retry-After', String(result.retryAfter));
        return res.status(429).json({ error: 'Too many support requests. Try again later.' });
      }

      return res.status(201).json({ reference: result.reference });
    } catch (err) {
      for (const attachment of attachments) {
        removeSupportScreenshotFile(attachment.storage_key);
      }
      return res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
