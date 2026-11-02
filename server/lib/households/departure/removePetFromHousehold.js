import { copyHouseholdContactsForPetLeave } from '../../people/contactCopyOnPetLeave.js';
import { recordPetAccessEvent } from '../accessAudit.js';
import { DEPARTURE_NOTICE_HOUSEHOLD_PET_REMOVED } from './notices.js';

/**
 * Remove one pet from a household inside an existing transaction (H4, D22 notice payload only).
 *
 * @param {import('pg').PoolClient} client
 * @param {{ householdId: string, petId: string, ownerUserId: string, copyToUserId?: string }} params
 * @returns {Promise<import('./notices.js').DepartureResult>}
 */
export async function removePetFromHousehold(client, {
  householdId,
  petId,
  ownerUserId,
  copyToUserId,
}) {
  const targetUserId = copyToUserId ?? ownerUserId;

  const petRow = await client.query('SELECT name FROM pets WHERE id = $1', [petId]);
  const petName = petRow.rows[0]?.name ?? null;

  await copyHouseholdContactsForPetLeave(client, petId, targetUserId, householdId);

  await client.query(
    'DELETE FROM household_pets WHERE household_id = $1 AND pet_id = $2',
    [householdId, petId],
  );

  await recordPetAccessEvent(client, {
    petId,
    eventType: 'pet_left_household',
    accessSource: 'household',
    detail: { household_id: householdId },
  });

  return {
    notices: [{
      kind: DEPARTURE_NOTICE_HOUSEHOLD_PET_REMOVED,
      householdId,
      petId,
      petName,
      actorUserId: null,
    }],
  };
}
