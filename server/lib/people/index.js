/**
 * People domain façade — other server packages should import only from here.
 */
export { PeopleError, PEOPLE_ERROR_CODES, asPeopleError } from './errors.js';
export {
  CONTACT_KINDS,
  CONTACT_ROLES,
  RELATIONSHIP_KINDS,
  ROLE_GROUP,
  SLOT_RELATIONSHIP_KINDS,
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
export { listUsages } from './usages.js';
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
export {
  listForPet,
  setSlot,
  add as addPetRelationship,
  remove as removePetRelationship,
  reorder as reorderPetRelationships,
  replaceAll as replacePetRelationships,
  setPrimaryVetFromLegacyVetId,
} from './relationships.js';
export {
  projectPet,
  projectContact,
  rebuildAll,
  createCompatVet,
  updateCompatVet,
  deleteCompatVet,
} from './vetProjection.js';
export { copyHouseholdContactsForPetLeave } from './contactCopyOnPetLeave.js';
export {
  resolveCarerWrite,
  enrichAbsencePetCarerContacts,
  deriveCarerState,
  contactOnAbsenceCarerRow,
} from './absenceCarer.js';
