import express from 'express';
import { createApiLimiter } from '../../config/rateLimit.js';
import { registerTransferRoutes } from './transferRouter.js';
import { registerFamilyEventsRoutes } from './familyEventsRouter.js';
import { registerPetAccessRoutes } from '../sharing/petAccessRoutes.js';
import { registerCarerCandidatesRoutes } from './carerCandidatesRouter.js';
import { registerLifecycleRoutes } from './lifecycleRouter.js';
import { registerCoreRoutes } from './coreRouter.js';
import { registerPhotoRoutes } from './photoRouter.js';
import { registerPetTagsRoutes } from './tagsRouter.js';
import { registerTimelineRoutes } from '../timeline/index.js';
import {
  registerCareIntelligenceRoutes,
  registerCareIntelligenceReviewRoutes,
  registerCareSafeguardRoutes,
} from '../careIntelligence/index.js';
import { registerCareProgressionRoutes } from '../index.js';
import { registerCareContextPetRoutes } from '../careContext/index.js';

export default function petsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  registerCareContextPetRoutes(router, pool);
  registerCarerCandidatesRoutes(router, pool);
  registerTransferRoutes(router, pool);
  registerFamilyEventsRoutes(router, pool);
  registerTimelineRoutes(router, pool);
  registerCareIntelligenceRoutes(router, pool);
  registerCareIntelligenceReviewRoutes(router, pool);
  registerCareSafeguardRoutes(router, pool);
  registerCareProgressionRoutes(router, pool);
  registerPetAccessRoutes(router, pool);
  registerLifecycleRoutes(router, pool);
  registerPhotoRoutes(router, pool);
  registerPetTagsRoutes(router, pool);
  registerCoreRoutes(router, pool);
  return router;
}

export { extractUserId, petRowToMap } from './shared.js';
