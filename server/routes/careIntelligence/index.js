import { registerCareIntelligenceRoutes } from './recommendationsRouter.js';
import { registerReviewRelevanceRoutes } from './reviewRelevanceRouter.js';
import { registerSafeguardRoutes } from './safeguardsRouter.js';

export { registerCareIntelligenceRoutes };

export function registerCareIntelligenceReviewRoutes(router, pool) {
  registerReviewRelevanceRoutes(router, pool);
}

export function registerCareSafeguardRoutes(router, pool) {
  registerSafeguardRoutes(router, pool);
}
