import express from 'express';
import { createApiLimiter } from '../../config/rateLimit.js';
import { registerInvitesRoutes } from './invitesRouter.js';
import { registerCoreRoutes } from './coreRouter.js';
import { registerMembersRoutes } from './membersRouter.js';
import { registerPetsRoutes } from './petsRouter.js';
import { registerFosterParentsRoutes } from './fosterParentsRouter.js';
import { registerFosterRequestsRoutes } from './fosterRequestsRouter.js';
import { registerProspectsRoutes } from './prospectsRouter.js';
import { registerAdoptionJourneysRoutes } from './adoptionJourneysRouter.js';
import { registerAdoptionVisitsRoutes } from './adoptionVisitsRouter.js';
import { registerDocumentTemplatesRoutes } from './documentTemplatesRouter.js';
import { registerPlacementsRoutes } from './placementsRouter.js';
import { registerConnectionRoutes } from './connectionsRouter.js';

export default function organizationsRoutes(pool) {
  const router = express.Router();
  router.use(createApiLimiter());
  registerConnectionRoutes(router, pool);
  registerInvitesRoutes(router, pool);
  registerCoreRoutes(router, pool);
  registerMembersRoutes(router, pool);
  registerPetsRoutes(router, pool);
  registerFosterParentsRoutes(router, pool);
  registerFosterRequestsRoutes(router, pool);
  registerProspectsRoutes(router, pool);
  registerAdoptionJourneysRoutes(router, pool);
  registerAdoptionVisitsRoutes(router, pool);
  registerDocumentTemplatesRoutes(router, pool);
  registerPlacementsRoutes(router, pool);
  return router;
}

export { getMemberRole, requireOrgAdmin, requireSuperAdmin } from './shared.js';
