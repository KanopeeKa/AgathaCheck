import { Router } from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { publicError } from '../../config/security.js';
import { requireAuth } from '../../lib/requireAuth.js';
import { userIsSupportStaff } from '../../lib/support/staff/staffFlag.js';
import {
  getSupportStaffTicketDetail,
  listSupportStaffTickets,
} from '../../lib/support/staff/queries.js';

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUuid(value) {
  return typeof value === 'string' && UUID_RE.test(value);
}

export default function supportStaffRoutes(pool) {
  const router = Router();
  router.use(createApiLimiter());
  router.use(requireAuth);

  router.use(async (req, res, next) => {
    try {
      const isStaff = await userIsSupportStaff(pool, req.userId);
      if (isStaff === null) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }
      if (!isStaff) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      return next();
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/tickets', async (req, res) => {
    try {
      const tickets = await listSupportStaffTickets(pool);
      return res.status(200).json({ tickets });
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  router.get('/tickets/:id', async (req, res) => {
    const ticketId = req.params.id;
    if (!isValidUuid(ticketId)) {
      return res.status(400).json({ error: 'Invalid ticket id' });
    }
    try {
      const detail = await getSupportStaffTicketDetail(pool, ticketId);
      if (!detail) {
        return res.status(404).json({ error: 'Ticket not found' });
      }
      return res.status(200).json(detail);
    } catch (err) {
      return res.status(500).json({ error: publicError(err) });
    }
  });

  return router;
}
