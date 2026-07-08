import { registerPlacementQueryRoutes } from './queryRouter.js';
import { registerPlacementCreateRoutes } from './createRouter.js';
import { registerPlacementActionRoutes } from './actionRouter.js';

export function registerPlacementsRoutes(router, pool) {
  registerPlacementQueryRoutes(router, pool);
  registerPlacementCreateRoutes(router, pool);
  registerPlacementActionRoutes(router, pool);
}
