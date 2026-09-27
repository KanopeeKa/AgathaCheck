import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import contactsRouter from './contactsRouter.js';

export default function peopleRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  router.use('/contacts', contactsRouter(pool));
  return router;
}
