import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerAbsenceContextRoutes } from './absenceContextRouter.js';
import { registerCrudRoutes } from './crudRouter.js';
import { registerCompletionRoutes } from './completionRouter.js';
import { registerDocumentsRoutes } from './documentsRouter.js';
import { registerEnsureOpenOccurrenceRoutes } from './ensureOpenOccurrenceRouter.js';
import { registerOccurrencePatchRoutes } from './occurrencePatchRouter.js';
import { asOfContextForEntry, registerOccurrenceRoutes } from './occurrencesRouter.js';
import { registerRescheduleOccurrenceRoutes } from './rescheduleOccurrenceRouter.js';
import { registerScheduleExplainRoutes } from './scheduleExplainRouter.js';

export default function healthEntriesRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());

  registerAbsenceContextRoutes(router, pool);
  registerCrudRoutes(router, pool);
  registerScheduleExplainRoutes(router, pool);
  registerEnsureOpenOccurrenceRoutes(router, pool, { asOfContextForEntry });
  registerOccurrenceRoutes(router, pool);
  registerOccurrencePatchRoutes(router, pool);
  registerRescheduleOccurrenceRoutes(router, pool);
  registerCompletionRoutes(router, pool);
  registerDocumentsRoutes(router, pool);

  return router;
}
