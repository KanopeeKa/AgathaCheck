import { v4 as uuidv4 } from 'uuid';

import { withTransaction } from '../db/withTransaction.js';
import {
  ensureHouseholdDirectory,
  userIsHouseholdMember,
  userIsHouseholdOrganiser,
} from './authz.js';
import { HOUSEHOLD_TIER_FULL } from './constants.js';
import { getHouseholdMemberRemovalPreview } from './memberRemoval.js';
import { removeHouseholdMember } from './lifecycle/index.js';
import { applySetHouseholdPets, setHouseholdPets } from './pets/setHouseholdPets.js';
import { emitHouseholdPetAdded } from '../notifications/relationshipEmitters.js';

export { getHouseholdMemberRemovalPreview, removeHouseholdMember, setHouseholdPets };

function mapHouseholdRow(row) {
  return {
    id: row.id,
    name: row.name,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function mapMemberRow(row) {
  return {
    user_id: row.user_id,
    access_tier: row.access_tier,
    is_organiser: row.is_organiser,
    joined_at: row.joined_at,
    user: {
      first_name: row.first_name || '',
      last_name: row.last_name || '',
      email: row.email || '',
      photo_url: row.photo_url || '',
    },
  };
}

export async function createHousehold(pool, userId, { name, petIds = [] }) {
  const trimmed = (name || '').trim();
  if (!trimmed) return { error: 'name is required', status: 400 };

  const householdId = uuidv4();
  const uniquePetIds = [...new Set((petIds || []).filter(Boolean))];

  /** @type {Awaited<ReturnType<typeof applySetHouseholdPets>>['addedNotices']} */
  let addedNotices = [];

  try {
    await withTransaction(pool, async (client) => {
      await client.query(
        `INSERT INTO households (id, name, created_at, updated_at)
         VALUES ($1, $2, NOW(), NOW())`,
        [householdId, trimmed],
      );
      await client.query(
        `INSERT INTO household_members (
           household_id, user_id, access_tier, is_organiser, joined_at
         ) VALUES ($1, $2, $3, true, NOW())`,
        [householdId, userId, HOUSEHOLD_TIER_FULL],
      );
      await ensureHouseholdDirectory(client, householdId);

      if (uniquePetIds.length > 0) {
        const putResult = await applySetHouseholdPets(client, userId, householdId, uniquePetIds);
        if (putResult.error) {
          const err = new Error(putResult.error);
          err.status = putResult.status;
          throw err;
        }
        addedNotices = putResult.addedNotices;
      }
    });
  } catch (err) {
    if (err.status) {
      return { error: err.message, status: err.status };
    }
    throw err;
  }

  for (const notice of addedNotices) {
    await emitHouseholdPetAdded(pool, {
      householdId: notice.householdId,
      petId: notice.petId,
      petName: notice.petName,
      actorUserId: notice.actorUserId,
    });
  }

  const household = await getHouseholdDetail(pool, userId, householdId);
  return { household };
}

export async function listHouseholdsForUser(db, userId) {
  const result = await db.query(
    `SELECT h.id, h.name, h.created_at, h.updated_at,
            hm.access_tier, hm.is_organiser
     FROM household_members hm
     INNER JOIN households h ON h.id = hm.household_id
     WHERE hm.user_id = $1
     ORDER BY h.name`,
    [userId],
  );
  return result.rows.map((row) => ({
    ...mapHouseholdRow(row),
    my_access_tier: row.access_tier,
    my_is_organiser: row.is_organiser,
  }));
}

export async function getHouseholdDetail(db, userId, householdId) {
  if (!(await userIsHouseholdMember(db, householdId, userId))) {
    return null;
  }
  const household = await db.query(
    'SELECT id, name, created_at, updated_at FROM households WHERE id = $1',
    [householdId],
  );
  if (household.rows.length === 0) return null;

  const members = await db.query(
    `SELECT hm.*, u.first_name, u.last_name, u.email, u.photo_url
     FROM household_members hm
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hm.household_id = $1
     ORDER BY hm.joined_at`,
    [householdId],
  );

  const pets = await db.query(
    `SELECT hp.pet_id, p.name, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1
     ORDER BY p.name`,
    [householdId],
  );

  return {
    ...mapHouseholdRow(household.rows[0]),
    members: members.rows.map(mapMemberRow),
    pets: pets.rows.map((r) => ({
      pet_id: r.pet_id,
      name: r.name,
      owner_user_id: r.owner_user_id,
    })),
  };
}

export async function patchHousehold(db, userId, householdId, body) {
  if (!(await userIsHouseholdOrganiser(db, householdId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const name = (body.name || '').trim();
  if (!name) return { error: 'name is required', status: 400 };
  await db.query(
    'UPDATE households SET name = $1, updated_at = NOW() WHERE id = $2',
    [name, householdId],
  );
  const household = await getHouseholdDetail(db, userId, householdId);
  return { household };
}
