import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerCrudRoutes } from './crudRouter.js';
import { registerCompletionRoutes } from './completionRouter.js';
import { registerDocumentsRoutes } from './documentsRouter.js';
import { registerOccurrenceRoutes } from './occurrencesRouter.js';

export default function healthEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  registerCrudRoutes(router, pool);
  registerOccurrenceRoutes(router, pool);
  registerCompletionRoutes(router, pool);
  registerDocumentsRoutes(router, pool);

  return router;
}
