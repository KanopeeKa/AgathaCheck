import { withTransaction } from '../db/withTransaction.js';
import { repointPetHouseholdContacts } from '../households/departure/contactRepoint.js';

function isPgPool(db) {
  return db != null && typeof db.connect === 'function' && typeof db.totalCount === 'number';
}

async function runInTransaction(db, fn) {
  if (isPgPool(db)) {
    return withTransaction(db, fn);
  }
  return fn(db);
}

/**
 * D23 / H4: when a pet leaves a household, copy household-directory contacts used by
 * the pet's data into the target user's personal directory and repoint references.
 *
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} petId
 * @param {string} ownerUserId — personal directory owner (copy target)
 * @param {string|null} householdId — household the pet is leaving (optional filter)
 */
export async function copyHouseholdContactsForPetLeave(db, petId, ownerUserId, householdId) {
  if (!petId || !ownerUserId) return;

  await runInTransaction(db, async (client) => {
    await repointPetHouseholdContacts(client, petId, ownerUserId, householdId);
  });
}
