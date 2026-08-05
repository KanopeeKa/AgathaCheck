/**
 * One-off splitter: organizations.js → organizations/*.js
 * Run from server/: node scripts/split-organizations-routes.mjs
 */
import fs from 'fs';
import path from 'path';

const src = fs.readFileSync('routes/organizations.js.bak', 'utf8');
const lines = src.split('\n');

function slice(start, end) {
  return lines.slice(start - 1, end).join('\n');
}

const sharedHeader = `import fs from 'fs';
import path from 'path';
import multer from 'multer';
import jwt from 'jsonwebtoken';

import { JWT_SECRET } from '../../config/jwtSecret.js';
import { isActiveMember, isOrgAdmin, isSuperAdmin, normaliseRole } from '../../lib/orgRoles.js';

`;

const sharedBody = slice(48, 219);
const sharedExports = `
export {
  ORG_COUNT_SELECT,
  orgUploadDir,
  saveOrgImage,
  handleOrgImageUpload,
  fetchOrgForUser,
  extractUserId,
  orgRowToMap,
  getMemberRole,
  requireMember,
  requireOrgAdmin,
  requireSuperAdmin,
};
`;

const shared = sharedHeader + sharedBody.replace(/^function /gm, 'function ')
  .replace(/^async function /gm, 'async function ')
  .replace(/^const /gm, 'const ')
  .replace(/^const ORG_COUNT_SELECT/gm, 'export const ORG_COUNT_SELECT')
  .replace(/^function orgUploadDir/gm, 'export function orgUploadDir')
  .replace(/^function saveOrgImage/gm, 'export function saveOrgImage')
  .replace(/^function handleOrgImageUpload/gm, 'export function handleOrgImageUpload')
  .replace(/^async function fetchOrgForUser/gm, 'export async function fetchOrgForUser')
  .replace(/^function extractUserId/gm, 'export function extractUserId')
  .replace(/^function orgRowToMap/gm, 'export function orgRowToMap')
  .replace(/^async function getMemberRole/gm, 'export async function getMemberRole')
  .replace(/^async function requireMember/gm, 'export async function requireMember')
  .replace(/^async function requireOrgAdmin/gm, 'export async function requireOrgAdmin')
  .replace(/^async function requireSuperAdmin/gm, 'export async function requireSuperAdmin');

fs.mkdirSync('routes/organizations', { recursive: true });

fs.writeFileSync('routes/organizations/shared.js', shared);

const modules = [
  { name: 'invitesRouter.js', start: 224, end: 286, imports: `import { extractUserId } from './shared.js';
import { publicError } from '../../config/security.js';
import { normaliseRole } from '../../lib/orgRoles.js';
` },
  { name: 'coreRouter.js', start: 288, end: 479, imports: `import { v4 as uuidv4 } from 'uuid';
import {
  ORG_COUNT_SELECT,
  extractUserId,
  fetchOrgForUser,
  handleOrgImageUpload,
  loadPrimaryContact,
  orgRowToMap,
  requireOrgAdmin,
  requireSuperAdmin,
  saveOrgImage,
} from './shared.js';
import { publicError } from '../../config/security.js';
import { ORG_ROLE_SUPER_ADMIN, isOrgAdmin, normaliseRole } from '../../lib/orgRoles.js';
` },
  { name: 'membersRouter.js', start: 481, end: 639, imports: `import { v4 as uuidv4 } from 'uuid';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';
import {
  ASSIGNABLE_ROLES,
  ORG_ROLE_ADMIN,
  canAssignRole,
  normaliseRole,
} from '../../lib/orgRoles.js';
import {
  getOrgPersonDetail,
  listOrgPeople,
  updateOrgPersonContact,
} from '../../lib/orgPeople.js';
` },
  { name: 'petsRouter.js', start: 641, end: 778, imports: `import { v4 as uuidv4 } from 'uuid';
import { dateToIsoDate, normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { transferOrgPetToUser } from '../../lib/orgPetTransfer.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';
` },
  { name: 'fosterParentsRouter.js', start: 780, end: 1024, imports: `import { v4 as uuidv4 } from 'uuid';
import { buildExternalFosterNoticeEmail } from '../../lib/email/templates/externalFosterNotice.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { OPEN_PLACEMENT_STATUSES } from '../../lib/fosterPlacements.js';
import { fosterParentMemberRolesSql, normaliseRole } from '../../lib/orgRoles.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';
` },
  { name: 'placementsRouter.js', start: 1026, end: 1522, imports: `import { v4 as uuidv4 } from 'uuid';
import { normalizeCalendarDateInput } from '../../lib/calendarDate.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import {
  cancelAdoptionPlacement,
  getActivePlacementForPet,
  loadPlacementDetail,
  placementToMap,
  PLACEMENT_STATUS_IN_PROGRESS,
  PLACEMENT_STATUS_NOT_IN_FOSTER,
  PLACEMENT_STATUS_PENDING,
  PLACEMENT_STATUS_PENDING_CONDITIONS,
  PLACEMENT_STATUS_WAITING_ADOPTION,
  revokeFosterPetAccess,
} from '../../lib/fosterPlacements.js';
import { isFosterParentMember } from '../../lib/orgRoles.js';
import { extractUserId, requireOrgAdmin } from './shared.js';
import { publicError } from '../../config/security.js';
` },
];

for (const mod of modules) {
  let body = slice(mod.start, mod.end);
  // fosterParents has nested function fosterParentToMap - keep it
  const fnName = mod.name.replace('.js', '');
  const content = `${mod.imports}
export function register${fnName.charAt(0).toUpperCase() + fnName.slice(1).replace('Router', 'Routes')}(router, pool) {
${body.split('\n').map((l) => (l ? `  ${l}` : l)).join('\n')}
}
`;
  fs.writeFileSync(`routes/organizations/${mod.name}`, content);
}

const index = `import express from 'express';
import { registerInvitesRoutes } from './invitesRouter.js';
import { registerCoreRoutes } from './coreRouter.js';
import { registerMembersRoutes } from './membersRouter.js';
import { registerPetsRoutes } from './petsRouter.js';
import { registerFosterParentsRoutes } from './fosterParentsRouter.js';
import { registerPlacementsRoutes } from './placementsRouter.js';

export default function organizationsRoutes(pool) {
  const router = express.Router();
  registerInvitesRoutes(router, pool);
  registerCoreRoutes(router, pool);
  registerMembersRoutes(router, pool);
  registerPetsRoutes(router, pool);
  registerFosterParentsRoutes(router, pool);
  registerPlacementsRoutes(router, pool);
  return router;
}

export { getMemberRole, requireOrgAdmin, requireSuperAdmin } from './shared.js';
`;

fs.writeFileSync('routes/organizations/index.js', index);

const shim = `export { default } from './organizations/index.js';
export { getMemberRole, requireOrgAdmin, requireSuperAdmin } from './organizations/shared.js';
`;

fs.writeFileSync('routes/organizations.js', shim);
console.log('Split complete.');
