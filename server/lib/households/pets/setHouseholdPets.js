import { withTransaction } from '../../db/withTransaction.js';
import { userOwnsPet } from '../../petAccess.js';
import { userIsHouseholdMember } from '../authz.js';
import { removePetFromHousehold } from '../departure/index.js';
import { getPetHouseholdId } from '../petAccessGrants.js';
import {
  emitHouseholdPetAdded,
  emitHouseholdPetRemoved,
} from '../../notifications/relationshipEmitters.js';
import { recordPetAccessEvent } from '../accessAudit.js';

async function listHouseholdPets(client, householdId) {
  const pets = await client.query(
    `SELECT hp.pet_id, p.name, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1
     ORDER BY p.name`,
    [householdId],
  );
  return pets.rows.map((r) => ({
    pet_id: r.pet_id,
    name: r.name,
    owner_user_id: r.owner_user_id,
  }));
}

/**
 * Apply pet membership changes inside an existing transaction (no notices).
 *
 * @param {import('pg').PoolClient} client
 */
export async function applySetHouseholdPets(client, userId, householdId, petIds) {
  const desired = [...new Set((petIds || []).filter(Boolean))];

  for (const petId of desired) {
    if (!(await userOwnsPet(client, petId, userId))) {
      return { error: 'You can only add pets you own', status: 403 };
    }
  }

  const current = await client.query(
    'SELECT pet_id FROM household_pets WHERE household_id = $1',
    [householdId],
  );
  const currentIds = new Set(current.rows.map((r) => r.pet_id));
  const desiredSet = new Set(desired);

  /** @type {{ kind: 'removed', householdId: string, petId: string, petName: string|null, actorUserId: string }[]} */
  const removedNotices = [];
  /** @type {{ kind: 'added', householdId: string, petId: string, petName: string|null, actorUserId: string }[]} */
  const addedNotices = [];

  for (const petId of currentIds) {
    if (!desiredSet.has(petId)) {
      const ownerRow = await client.query('SELECT user_id FROM pets WHERE id = $1', [petId]);
      const ownerId = ownerRow.rows[0]?.user_id;
      if (ownerId === userId) {
        const result = await removePetFromHousehold(client, {
          householdId,
          petId,
          ownerUserId: ownerId,
        });
        const notice = result.notices[0];
        removedNotices.push({
          kind: 'removed',
          householdId,
          petId,
          petName: notice?.petName ?? null,
          actorUserId: userId,
        });
      }
    }
  }

  for (const petId of desired) {
    if (currentIds.has(petId)) continue;

    const otherHousehold = await getPetHouseholdId(client, petId);
    if (otherHousehold && otherHousehold !== householdId) {
      return { error: 'Pet is already in another household', status: 409 };
    }

    const insertResult = await client.query(
      `INSERT INTO household_pets (household_id, pet_id, added_at)
       VALUES ($1, $2, NOW())
       ON CONFLICT (pet_id) DO NOTHING
       RETURNING pet_id`,
      [householdId, petId],
    );

    if (insertResult.rows.length === 0) {
      const existingHousehold = await getPetHouseholdId(client, petId);
      if (existingHousehold && existingHousehold !== householdId) {
        return { error: 'Pet is already in another household', status: 409 };
      }
      continue;
    }

    const petNameRow = await client.query('SELECT name FROM pets WHERE id = $1', [petId]);
    await recordPetAccessEvent(client, {
      petId,
      eventType: 'pet_joined_household',
      accessSource: 'household',
      detail: { household_id: householdId },
    });
    addedNotices.push({
      kind: 'added',
      householdId,
      petId,
      petName: petNameRow.rows[0]?.name ?? null,
      actorUserId: userId,
    });
  }

  const pets = await listHouseholdPets(client, householdId);
  return { pets, addedNotices, removedNotices };
}

/**
 * @param {import('pg').Pool} pool
 */
export async function setHouseholdPets(pool, userId, householdId, petIds) {
  if (!(await userIsHouseholdMember(pool, householdId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }

  let addedNotices = [];
  let removedNotices = [];

  const result = await withTransaction(pool, async (client) => {
    const applied = await applySetHouseholdPets(client, userId, householdId, petIds);
    if (applied.error) {
      const err = new Error(applied.error);
      err.status = applied.status;
      throw err;
    }
    addedNotices = applied.addedNotices;
    removedNotices = applied.removedNotices;
    return applied.pets;
  }).catch((err) => {
    if (err.status) {
      return { error: err.message, status: err.status };
    }
    throw err;
  });

  if (result?.error) return result;

  for (const notice of removedNotices) {
    await emitHouseholdPetRemoved(pool, {
      householdId: notice.householdId,
      petId: notice.petId,
      petName: notice.petName,
      actorUserId: notice.actorUserId,
    });
  }
  for (const notice of addedNotices) {
    await emitHouseholdPetAdded(pool, {
      householdId: notice.householdId,
      petId: notice.petId,
      petName: notice.petName,
      actorUserId: notice.actorUserId,
    });
  }

  return { pets: result };
}
