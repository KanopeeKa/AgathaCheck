import { registerCareIntelligenceRoutes } from './recommendationsRouter.js';
import { registerReviewRelevanceRoutes } from './reviewRelevanceRouter.js';
import { registerSafeguardRoutes } from './safeguardsRouter.js';
import { registerWelfareSuggestionRoutes } from './welfareSuggestionsRouter.js';

export { registerCareIntelligenceRoutes };

export function registerWelfareSuggestionRoutesForPets(router, pool) {
  registerWelfareSuggestionRoutes(router, pool);
}

export function registerCareIntelligenceReviewRoutes(router, pool) {
  registerReviewRelevanceRoutes(router, pool);
}

export function registerCareSafeguardRoutes(router, pool) {
  registerSafeguardRoutes(router, pool);
}
