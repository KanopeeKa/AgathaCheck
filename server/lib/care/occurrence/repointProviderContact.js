/**
 * Repoint provider_contact_id on occurrences (write-path guard home for this SQL).
 */

/**
 * @param {import('pg').PoolClient|import('pg').Pool} db
 * @param {string} petId
 * @param {string} sourceContactId
 * @param {string} targetContactId
 */
export async function repointProviderContactForPet(db, petId, sourceContactId, targetContactId) {
  if (sourceContactId === targetContactId) return;
  await db.query(
    `UPDATE health_occurrences ho
     SET provider_contact_id = $1, updated_at = NOW()
     FROM health_entries he
     WHERE ho.health_entry_id = he.id
       AND he.pet_id = $2
       AND ho.provider_contact_id = $3`,
    [targetContactId, petId, sourceContactId],
  );
}
