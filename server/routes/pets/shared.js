import { extractUserId as centralExtractUserId } from '../../lib/requireAuth.js';

export {
  FOSTER_PLACEMENT_SELECT_SQL,
  PET_PARENT_NAME_SELECT_SQL,
  PRIMARY_HOLDER_NAME_SELECT_SQL,
  petRowToMap,
  autoAssignColors,
  userInOrg,
} from '../../lib/pets/petPresentation.js';

export function extractUserId(req) {
  return centralExtractUserId(req);
}
