import { registerCareProgressionReadRoutes } from './readRouter.js';
import { registerCareProgressionReEvaluateRoutes } from './reEvaluateRouter.js';
import { registerCompleteWeightRoutes } from '../healthEntries/completeWeightRouter.js';

export function registerCareProgressionRoutes(router, pool) {
  registerCareProgressionReadRoutes(router, pool);
  registerCareProgressionReEvaluateRoutes(router, pool);
  registerCompleteWeightRoutes(router, pool);
}
