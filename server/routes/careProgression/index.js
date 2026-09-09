import { registerCareProgressionReadRoutes } from './readRouter.js';
import { registerCompleteWeightRoutes } from '../healthEntries/completeWeightRouter.js';

export function registerCareProgressionRoutes(router, pool) {
  registerCareProgressionReadRoutes(router, pool);
  registerCompleteWeightRoutes(router, pool);
}
