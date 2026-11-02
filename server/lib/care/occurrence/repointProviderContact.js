/**
 * Repoint provider_contact_id on occurrences when a pet's contact reference changes.
 * Write-path guard: health_occurrences updates live under server/lib/care/occurrence/**.
 */

/**
 * @param {import('pg').PoolClient} client
 * @param {{ petId: string, sourceContactId: string, targetContactId: string }} params
 */
export async function repointProviderContactForPet(client, {
  petId, sourceContactId, targetContactId,
}) {
  if (sourceContactId === targetContactId) return;
  await client.query(
    `UPDATE health_occurrences ho
     SET provider_contact_id = $1, updated_at = NOW()
     FROM health_entries he
     WHERE ho.health_entry_id = he.id
       AND he.pet_id = $2
       AND ho.provider_contact_id = $3`,
    [targetContactId, petId, sourceContactId],
  );
}
