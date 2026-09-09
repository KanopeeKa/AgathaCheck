import { registerCareProgressionReadRoutes } from './readRouter.js';

export function registerCareProgressionRoutes(router, pool) {
  registerCareProgressionReadRoutes(router, pool);
}
