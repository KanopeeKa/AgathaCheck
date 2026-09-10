import express from 'express';

import { createApiLimiter } from '../../config/rateLimit.js';
import { registerPlannedAbsenceRoutes } from './plannedAbsencesRouter.js';
import { registerCarePeriodProjectionRoutes } from './carePeriodProjectionRouter.js';
import { registerCarePeriodCoverageRoutes } from './carePeriodCoverageRouter.js';

export default function careContextRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  registerPlannedAbsenceRoutes(router, pool);
  return router;
}

export function registerCareContextPetRoutes(router, pool) {
  registerCarePeriodProjectionRoutes(router, pool);
  registerCarePeriodCoverageRoutes(router, pool);
}
