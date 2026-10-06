import { registerPlannedAbsenceCarerInviteRoutes } from './plannedAbsenceCarerInviteRoutes.js';
import { registerAbsenceCarePlanRoutes } from './absenceCarePlanRouter.js';
import { registerPlannedAbsenceHandoverRoutes } from './plannedAbsenceHandoverRoutes.js';
import { registerAbsenceResolutionsRoutes } from './absenceResolutionsRouter.js';
import { registerPlannedAbsenceCoreRoutes } from './plannedAbsenceCoreRouter.js';
import {
  loadAbsenceForUser,
  loadAbsencePets,
} from './plannedAbsenceStore.js';

export function registerPlannedAbsenceRoutes(router, pool) {
  registerPlannedAbsenceCarerInviteRoutes(router, pool);
  registerPlannedAbsenceCoreRoutes(router, pool);
  registerPlannedAbsenceHandoverRoutes(router, pool, {
    loadAbsenceForUser,
    loadAbsencePets,
  });
  registerAbsenceCarePlanRoutes(router, pool, {
    loadAbsenceForUser,
    loadAbsencePets,
  });
  registerAbsenceResolutionsRoutes(router, pool, {
    loadAbsenceForUser,
    loadAbsencePets,
  });
}
