import {
  deactivateOrDeleteContactForVet,
  upsertContactFromVetFields,
} from './contactsRepo.js';

function vetToContactFields(vetRow) {
  const clinic = (vetRow.clinic || '').trim();
  const personName = (vetRow.name || '').trim();
  const kind = clinic ? 'organisation' : 'person';
  const name = clinic || personName || 'Vet';
  const privateNote = (vetRow.notes || '').trim();
  return {
    kind,
    name,
    phone: vetRow.phone || null,
    email: vetRow.email || null,
    website: vetRow.website || '',
    address: vetRow.address || '',
    privateNote,
  };
}

/**
 * Create or update people_contact linked to a vet row.
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {object} vetRow vets RETURNING row
 * @param {string} userId
 */
export async function upsertContactFromVet(pool, vetRow, userId) {
  if (!vetRow?.id || !userId) return null;
  const fields = vetToContactFields(vetRow);
  return upsertContactFromVetFields(pool, {
    ...fields,
    legacy_vet_id: vetRow.id,
  }, userId);
}

export {
  ensureLegacyVetForContact,
  syncVetRowFromContact,
  deleteLegacyVetRowForContact,
} from './vetProjection.js';

export async function deleteContactForVet(pool, vetId) {
  await deactivateOrDeleteContactForVet(pool, vetId);
}
