import { registerCareIntelligenceRoutes } from './recommendationsRouter.js';
import { registerReviewRelevanceRoutes } from './reviewRelevanceRouter.js';

export { registerCareIntelligenceRoutes };

export function registerCareIntelligenceReviewRoutes(router, pool) {
  registerReviewRelevanceRoutes(router, pool);
}
