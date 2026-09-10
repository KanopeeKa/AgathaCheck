import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerPlannedAbsenceRoutes } from './plannedAbsencesRouter.js';

export default function careContextRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  registerPlannedAbsenceRoutes(router, pool);
  return router;
}
