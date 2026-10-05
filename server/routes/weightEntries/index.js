import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { createWeightEntriesReadRouter } from './readRouter.js';
import { createWeightEntriesWriteRouter } from './writeRouter.js';

export default function weightEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  router.use(createWeightEntriesReadRouter(pool));
  router.use(createWeightEntriesWriteRouter(pool));
  return router;
}
