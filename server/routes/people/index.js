import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import contactsReadRouter from './contactsReadRouter.js';
import contactsRouter from './contactsRouter.js';
import rosterRouter from './rosterRouter.js';

export default function peopleRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  router.use('/roster', rosterRouter(pool));
  router.use('/contacts', contactsReadRouter(pool));
  router.use('/contacts', contactsRouter(pool));
  return router;
}
