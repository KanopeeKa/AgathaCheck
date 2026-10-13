import { registerCareIntelligenceRoutes } from './recommendationsRouter.js';
import { registerReviewRelevanceRoutes } from './reviewRelevanceRouter.js';
import { registerSafeguardRoutes } from './safeguardsRouter.js';
import { registerWelfareSuggestionRoutes } from './welfareSuggestionsRouter.js';
import { syncPetWelfareSuggestions } from './welfare/syncPetWelfareSuggestions.js';

export { registerCareIntelligenceRoutes };

/** AC-FB-01: reconcile welfare rows after profile PUT (pets route calls via index only). */
export async function reconcilePetWelfareAfterProfileUpdate(pool, pet) {
  if (!pet) return;
  await syncPetWelfareSuggestions(pool, pet);
}

export function registerWelfareSuggestionRoutesForPets(router, pool) {
  registerWelfareSuggestionRoutes(router, pool);
}

export function registerCareIntelligenceReviewRoutes(router, pool) {
  registerReviewRelevanceRoutes(router, pool);
}

export function registerCareSafeguardRoutes(router, pool) {
  registerSafeguardRoutes(router, pool);
}
