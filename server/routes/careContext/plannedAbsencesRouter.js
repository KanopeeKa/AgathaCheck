import { registerPlannedAbsenceCarerInviteRoutes } from './plannedAbsenceCarerInviteRoutes.js';
import { registerPerPetAwayPlanRoutes } from './perPetAwayPlanRouter.js';
import { registerAbsenceCarePlanRoutes } from './absenceCarePlanRouter.js';
import { registerPlannedAbsenceHandoverRoutes } from './plannedAbsenceHandoverRoutes.js';
import { registerAbsenceResolutionsRoutes } from './absenceResolutionsRouter.js';
import { registerPlannedAbsenceCoreRoutes } from './plannedAbsenceCoreRouter.js';
import { loadAbsenceForViewer } from '../../lib/care/absence/absenceVisibility.js';
import {
  loadAbsenceForUser,
  loadAbsencePets,
} from './plannedAbsenceStore.js';

export function registerPlannedAbsenceRoutes(router, pool) {
  registerPlannedAbsenceCarerInviteRoutes(router, pool);
  registerPerPetAwayPlanRoutes(router, pool);
  registerPlannedAbsenceCoreRoutes(router, pool);
  registerPlannedAbsenceHandoverRoutes(router, pool, {
    loadAbsenceForUser,
    loadAbsencePets,
  });
  registerAbsenceCarePlanRoutes(router, pool, {
    loadAbsenceForViewer,
    loadAbsencePets,
  });
  registerAbsenceResolutionsRoutes(router, pool, {
    loadAbsenceForViewer,
    loadAbsencePets,
  });
}
