import express from 'express';
import { createApiLimiter } from '../../config/rateLimit.js';
import { registerTransferRoutes } from './transferRouter.js';
import { registerFamilyEventsRoutes } from './familyEventsRouter.js';
import { registerAccessRoutes } from './accessRouter.js';
import { registerLifecycleRoutes } from './lifecycleRouter.js';
import { registerCoreRoutes } from './coreRouter.js';

export default function petsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  registerTransferRoutes(router, pool);
  registerFamilyEventsRoutes(router, pool);
  registerAccessRoutes(router, pool);
  registerLifecycleRoutes(router, pool);
  registerCoreRoutes(router, pool);
  return router;
}

export { extractUserId, petRowToMap } from './shared.js';
