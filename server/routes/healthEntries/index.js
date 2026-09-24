import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerCrudRoutes } from './crudRouter.js';
import { registerCompletionRoutes } from './completionRouter.js';
import { registerDocumentsRoutes } from './documentsRouter.js';
import { registerOccurrenceRoutes } from './occurrencesRouter.js';
import { registerRescheduleOccurrenceRoutes } from './rescheduleOccurrenceRouter.js';
import { registerScheduleExplainRoutes } from './scheduleExplainRouter.js';

export default function healthEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  registerCrudRoutes(router, pool);
  registerScheduleExplainRoutes(router, pool);
  registerOccurrenceRoutes(router, pool);
  registerRescheduleOccurrenceRoutes(router, pool);
  registerCompletionRoutes(router, pool);
  registerDocumentsRoutes(router, pool);

  return router;
}
