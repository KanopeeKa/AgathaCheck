/** Notice kinds returned by departure primitives for after-commit emission. */
export const DEPARTURE_NOTICE_HOUSEHOLD_PET_REMOVED = 'household_pet_removed';

/**
 * @typedef {object} HouseholdPetRemovedNotice
 * @property {'household_pet_removed'} kind
 * @property {string} householdId
 * @property {string} petId
 * @property {string|null} petName
 * @property {string|null} [actorUserId]
 */

/**
 * @typedef {object} DepartureResult
 * @property {HouseholdPetRemovedNotice[]} notices
 */
