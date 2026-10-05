import { deactivateOrDeleteContactForVet } from './contactsRepo.js';

export {
  deleteLegacyVetRowForContact,
  ensureLegacyVetForContact,
  syncVetRowFromContact,
  upsertContactFromVet,
} from './vetProjection.js';

export async function deleteContactForVet(pool, vetId) {
  await deactivateOrDeleteContactForVet(pool, vetId);
}
