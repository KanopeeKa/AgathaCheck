import { registerCrudCreateRoutes } from './crudCreateRouter.js';
import { registerCrudDeleteRoutes } from './crudDeleteRouter.js';
import { registerCrudReadRoutes } from './crudReadRouter.js';
import { registerCrudUpdateRoutes } from './crudUpdateRouter.js';

/** Wires health entry CRUD HTTP routes; use-case logic lives in server/lib/health/*. */
export function registerCrudRoutes(router, pool) {
  registerCrudReadRoutes(router, pool);
  registerCrudCreateRoutes(router, pool);
  registerCrudUpdateRoutes(router, pool);
  registerCrudDeleteRoutes(router, pool);
}
