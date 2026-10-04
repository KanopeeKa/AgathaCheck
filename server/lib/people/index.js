/**
 * People domain façade — other server packages should import only from here.
 */
export { PeopleError, PEOPLE_ERROR_CODES, asPeopleError } from './errors.js';
export {
  CONTACT_KINDS,
  CONTACT_ROLES,
  RELATIONSHIP_KINDS,
  ROLE_GROUP,
} from './constants.js';
export { inferContactKind, contactGroup } from './inference.js';
export {
  visibleDirectoryIds,
  canViewContact,
  canEditContact,
  canAttachContactToPet,
  careHandoverScope,
  getPetOwnerUserId,
  contactInEditableDirectoriesForPet,
} from './access.js';
export {
  createPersonalContact,
  patchPersonalContact,
  deletePersonalContact,
  ensureLinkedUserContact,
  ensureNoteOnlyContact,
  upsertContactFromVetFields,
  deactivateOrDeleteContactForVet,
} from './contactsRepo.js';
export {
  userOwnsContact,
  contactUsableForPet,
} from './authz.js';
export { ensurePersonalDirectory, getPersonalDirectoryId } from './directory.js';
export { contactRowToMap, loadContactForViewer, listContactsInDirectory } from './contactMapping.js';
export {
  upsertContactFromVet,
  ensureLegacyVetForContact,
  syncVetRowFromContact,
  deleteContactForVet,
} from './vetSync.js';
export { copyHouseholdContactsForPetLeave } from './contactCopyOnPetLeave.js';
export {
  resolveCarerWrite,
  enrichAbsencePetCarerContacts,
  deriveCarerState,
  contactOnAbsenceCarerRow,
} from './absenceCarer.js';
