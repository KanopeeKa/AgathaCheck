/**
 * Pet sharing permission matrix — maps capabilities to access helpers.
 */
import {
  CARER_ROLE,
  CO_PARENT_ROLE,
  userCanManageCare,
  userCanManageProfile,
  userCanSharePet,
  userOwnsPet,
} from '../petAccess.js';

export { CARER_ROLE, CO_PARENT_ROLE };

export function normalizeShareAccessRole(raw) {
  const value = String(raw || '').trim();
  if (value === CO_PARENT_ROLE || value === 'coParent') return CO_PARENT_ROLE;
  return CARER_ROLE;
}

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} petId
 * @param {string} userId
 * @param {'care' | 'profile' | 'sharing' | 'transfer'} action
 */
export async function canPerformSharingAction(pool, petId, userId, action) {
  switch (action) {
    case 'care':
      return userCanManageCare(pool, petId, userId);
    case 'profile':
      return userCanManageProfile(pool, petId, userId);
    case 'sharing':
      return userCanSharePet(pool, petId, userId);
    case 'transfer':
      return userOwnsPet(pool, petId, userId);
    default:
      return false;
  }
}
