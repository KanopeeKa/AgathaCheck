import { registerPlacementQueryRoutes } from './queryRouter.js';
import { registerPlacementCreateRoutes } from './createRouter.js';
import { registerPlacementActionRoutes } from './actionRouter.js';
import { registerPlacementSessionLifecycleRoutes } from './sessionLifecycleRouter.js';

export function registerPlacementsRoutes(router, pool) {
  registerPlacementQueryRoutes(router, pool);
  registerPlacementCreateRoutes(router, pool);
  registerPlacementSessionLifecycleRoutes(router, pool);
  registerPlacementActionRoutes(router, pool);
}
