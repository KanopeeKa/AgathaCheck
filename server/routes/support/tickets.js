import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import multer from 'multer';

import { publicError } from '../../config/security.js';
import { createSupportTicket } from '../../lib/support/submit/createTicket.js';
import { resolveSupportSubmitAuth } from '../../lib/support/submit/authContext.js';
import { parseSupportTicketPayload } from '../../lib/support/submit/parseTicketPayload.js';
import { assertSupportScreenshotGate } from '../../lib/support/submit/screenshot_gate.js';
import { validateSupportTicketBody } from '../../lib/support/schema/validateTicketBody.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { files: 3 },
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

  router.post('/tickets', upload.any(), async (req, res) => {
    const auth = resolveSupportSubmitAuth(req);
    if (auth.status === 'invalid') {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    const screenshotGate = assertSupportScreenshotGate(req);
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

    try {
      const result = await createSupportTicket(pool, {
        signedIn,
        userId: signedIn ? auth.userId : null,
        accountEmail,
        body: validated.value,
        clientIp,
      });

      if (result.error === 'rate_limited') {
        res.setHeader('Retry-After', String(result.retryAfter));
        return res.status(429).json({ error: 'Too many support requests. Try again later.' });
      }

      return res.status(201).json({ reference: result.reference });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
