import { registerCoreListRoutes } from './coreListRouter.js';
import { registerCoreWriteRoutes } from './coreWriteRouter.js';

/** HTTP registration for pet core CRUD; business rules live in server/lib/pets/*. */
export function registerCoreRoutes(router, pool) {
  registerCoreListRoutes(router, pool);
  registerCoreWriteRoutes(router, pool);
}
