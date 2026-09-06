/** Pet capability policy — maps discovery capability seeds to access helpers. */
import {
  userCanAccessPet,
  userCanManagePet,
  userCanSharePet,
  userOwnsPet,
} from './petAccess.js';

/** @readonly */
export const PET_CAPABILITIES = Object.freeze({
  VIEW: 'pet.view',
  PROFILE_EDIT: 'pet.profile.edit',
  DELETE: 'pet.delete',
  LIFECYCLE_MANAGE: 'pet.lifecycle.manage',
  HEALTH_VIEW: 'pet.health.view',
  HEALTH_EDIT: 'pet.health.edit',
  HEALTH_DOCUMENTS_MANAGE: 'pet.health.documents.manage',
  WEIGHT_VIEW: 'pet.weight.view',
  WEIGHT_EDIT: 'pet.weight.edit',
  VET_VIEW: 'pet.vet.view',
  VET_EDIT: 'pet.vet.edit',
  SHARING_MANAGE: 'pet.sharing.manage',
  NOTIFICATIONS_MANAGE: 'pet.notifications.manage',
  TIMELINE_OWN_NOTES: 'pet.timeline.own_notes',
  FOSTER_REPORT: 'pet.foster.report',
});

const ALL_CAPABILITIES = new Set(Object.values(PET_CAPABILITIES));

/**
 * @param {import('pg').Pool | import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} petId
 * @param {string} capability
 * @returns {Promise<boolean>}
 */
export async function hasPetCapability(pool, userId, petId, capability) {
  if (!userId || !petId || !capability || !ALL_CAPABILITIES.has(capability)) {
    return false;
  }

  switch (capability) {
    case PET_CAPABILITIES.VIEW:
    case PET_CAPABILITIES.HEALTH_VIEW:
    case PET_CAPABILITIES.WEIGHT_VIEW:
    case PET_CAPABILITIES.VET_VIEW:
    case PET_CAPABILITIES.FOSTER_REPORT:
      return userCanAccessPet(pool, petId, userId);
    case PET_CAPABILITIES.SHARING_MANAGE:
      return userCanSharePet(pool, petId, userId);
    case PET_CAPABILITIES.DELETE:
    case PET_CAPABILITIES.LIFECYCLE_MANAGE:
      return userOwnsPet(pool, petId, userId);
    case PET_CAPABILITIES.PROFILE_EDIT:
    case PET_CAPABILITIES.HEALTH_EDIT:
    case PET_CAPABILITIES.HEALTH_DOCUMENTS_MANAGE:
    case PET_CAPABILITIES.WEIGHT_EDIT:
    case PET_CAPABILITIES.VET_EDIT:
    case PET_CAPABILITIES.NOTIFICATIONS_MANAGE:
    case PET_CAPABILITIES.TIMELINE_OWN_NOTES:
      return userCanManagePet(pool, petId, userId);
    default:
      return false;
  }
}
