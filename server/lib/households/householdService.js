import { v4 as uuidv4 } from 'uuid';

import { deleteAccessForTargetUser } from '../../db/sharing/shareAccessQueries.js';
import { userOwnsPet } from '../petAccess.js';
import { copyHouseholdContactsForPetLeave } from '../people/contactCopyOnPetLeave.js';
import { recordPetAccessEvent } from './accessAudit.js';
import {
  ensureHouseholdDirectory,
  getHouseholdMembership,
  userIsHouseholdMember,
  userIsHouseholdOrganiser,
} from './authz.js';
import {
  HOUSEHOLD_TIER_FULL,
  isHouseholdTier,
  normalizeMemberTier,
} from './constants.js';
import { getPetHouseholdId } from './petAccessGrants.js';

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

export async function createHousehold(db, userId, { name, petIds = [] }) {
  const trimmed = (name || '').trim();
  if (!trimmed) return { error: 'name is required', status: 400 };

  const householdId = uuidv4();
  await db.query(
    `INSERT INTO households (id, name, created_at, updated_at)
     VALUES ($1, $2, NOW(), NOW())`,
    [householdId, trimmed],
  );
  await db.query(
    `INSERT INTO household_members (
       household_id, user_id, access_tier, is_organiser, joined_at
     ) VALUES ($1, $2, $3, true, NOW())`,
    [householdId, userId, HOUSEHOLD_TIER_FULL],
  );
  await ensureHouseholdDirectory(db, householdId);

  const uniquePetIds = [...new Set((petIds || []).filter(Boolean))];
  if (uniquePetIds.length > 0) {
    const putResult = await setHouseholdPets(db, userId, householdId, uniquePetIds);
    if (putResult.error) {
      await db.query('DELETE FROM households WHERE id = $1', [householdId]);
      return putResult;
    }
  }

  const household = await getHouseholdDetail(db, userId, householdId);
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

export async function addHouseholdMember(db, actorId, householdId, body) {
  if (!(await userIsHouseholdOrganiser(db, householdId, actorId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const targetUserId = body.user_id || body.userId;
  if (!targetUserId) {
    return { error: 'user_id is required (invite tokens ship in a later phase)', status: 400 };
  }
  const userExists = await db.query('SELECT 1 FROM users WHERE id = $1', [targetUserId]);
  if (userExists.rows.length === 0) {
    return { error: 'User not found', status: 404 };
  }
  const existing = await getHouseholdMembership(db, householdId, targetUserId);
  if (existing) return { error: 'User is already a member', status: 409 };

  let accessTier = body.access_tier || body.accessTier || HOUSEHOLD_TIER_FULL;
  const isOrganiser = Boolean(body.is_organiser ?? body.isOrganiser);
  if (!isHouseholdTier(accessTier) && !isOrganiser) {
    return { error: 'Invalid access_tier', status: 400 };
  }
  accessTier = normalizeMemberTier({ accessTier, isOrganiser });

  await db.query(
    `INSERT INTO household_members (
       household_id, user_id, access_tier, is_organiser, joined_at
     ) VALUES ($1, $2, $3, $4, NOW())`,
    [householdId, targetUserId, accessTier, isOrganiser],
  );

  const member = await db.query(
    `SELECT hm.*, u.first_name, u.last_name, u.email, u.photo_url
     FROM household_members hm
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hm.household_id = $1 AND hm.user_id = $2`,
    [householdId, targetUserId],
  );
  return { member: mapMemberRow(member.rows[0]) };
}

export async function removeHouseholdMember(db, actorId, householdId, targetUserId, options = {}) {
  const actorMembership = await getHouseholdMembership(db, householdId, actorId);
  if (!actorMembership) return { error: 'Forbidden', status: 403 };

  const selfLeave = actorId === targetUserId;
  if (!selfLeave && !actorMembership.is_organiser) {
    return { error: 'Forbidden', status: 403 };
  }

  const targetMembership = await getHouseholdMembership(db, householdId, targetUserId);
  if (!targetMembership) return { error: 'Member not found', status: 404 };

  const removePetAccess = options.remove_all_access_to_my_pets === true
    || options.removeAllAccessToMyPets === true;

  await db.query(
    'DELETE FROM household_members WHERE household_id = $1 AND user_id = $2',
    [householdId, targetUserId],
  );

  if (removePetAccess && actorMembership.is_organiser) {
    const ownedPets = await db.query(
      `SELECT hp.pet_id FROM household_pets hp
       INNER JOIN pets p ON p.id = hp.pet_id
       WHERE hp.household_id = $1 AND p.user_id = $2`,
      [householdId, actorId],
    );
    for (const row of ownedPets.rows) {
      await deleteAccessForTargetUser(db, row.pet_id, targetUserId);
    }
  }

  const remainingOrganisers = await db.query(
    `SELECT user_id FROM household_members
     WHERE household_id = $1 AND is_organiser = true`,
    [householdId],
  );
  if (remainingOrganisers.rows.length === 0) {
    const memberCount = await db.query(
      'SELECT count(*)::int AS c FROM household_members WHERE household_id = $1',
      [householdId],
    );
    if (memberCount.rows[0].c === 0) {
      await db.query('DELETE FROM households WHERE id = $1', [householdId]);
    }
  }

  return { message: 'Member removed' };
}

export async function setHouseholdPets(db, userId, householdId, petIds) {
  if (!(await userIsHouseholdMember(db, householdId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const desired = [...new Set((petIds || []).filter(Boolean))];

  for (const petId of desired) {
    if (!(await userOwnsPet(db, petId, userId))) {
      return { error: 'You can only add pets you own', status: 403 };
    }
    const otherHousehold = await getPetHouseholdId(db, petId);
    if (otherHousehold && otherHousehold !== householdId) {
      return { error: 'Pet is already in another household', status: 409 };
    }
  }

  const current = await db.query(
    'SELECT pet_id FROM household_pets WHERE household_id = $1',
    [householdId],
  );
  const currentIds = new Set(current.rows.map((r) => r.pet_id));
  const desiredSet = new Set(desired);

  for (const petId of currentIds) {
    if (!desiredSet.has(petId)) {
      const ownerRow = await db.query('SELECT user_id FROM pets WHERE id = $1', [petId]);
      const ownerId = ownerRow.rows[0]?.user_id;
      if (ownerId === userId) {
        await copyHouseholdContactsForPetLeave(db, petId, ownerId, householdId);
        await db.query('DELETE FROM household_pets WHERE pet_id = $1', [petId]);
        await recordPetAccessEvent(db, {
          petId,
          eventType: 'pet_left_household',
          accessSource: 'household',
          detail: { household_id: householdId },
        });
      }
    }
  }

  for (const petId of desired) {
    if (!currentIds.has(petId)) {
      await db.query(
        `INSERT INTO household_pets (household_id, pet_id, added_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT (pet_id) DO UPDATE SET household_id = EXCLUDED.household_id`,
        [householdId, petId],
      );
      await recordPetAccessEvent(db, {
        petId,
        eventType: 'pet_joined_household',
        accessSource: 'household',
        detail: { household_id: householdId },
      });
    }
  }

  const pets = await db.query(
    `SELECT hp.pet_id, p.name, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = $1`,
    [householdId],
  );
  return {
    pets: pets.rows.map((r) => ({
      pet_id: r.pet_id,
      name: r.name,
      owner_user_id: r.owner_user_id,
    })),
  };
}
