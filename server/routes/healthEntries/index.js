import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerAbsenceContextRoutes } from './absenceContextRouter.js';
import { registerCrudRoutes } from './crudRouter.js';
import { registerCompletionRoutes } from './completionRouter.js';
import { registerDocumentsRoutes } from './documentsRouter.js';
import { registerOccurrencePatchRoutes } from './occurrencePatchRouter.js';
import { registerOccurrenceRoutes } from './occurrencesRouter.js';
import { registerRescheduleOccurrenceRoutes } from './rescheduleOccurrenceRouter.js';
import { registerScheduleExplainRoutes } from './scheduleExplainRouter.js';
import { registerScheduleRoutes } from './scheduleRouter.js';

export default function healthEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  registerAbsenceContextRoutes(router, pool);
  registerCrudRoutes(router, pool);
  registerScheduleExplainRoutes(router, pool);
  registerOccurrenceRoutes(router, pool);
  registerOccurrencePatchRoutes(router, pool);
  registerRescheduleOccurrenceRoutes(router, pool);
  registerScheduleRoutes(router, pool);
  registerCompletionRoutes(router, pool);
  registerDocumentsRoutes(router, pool);

  return router;
}
