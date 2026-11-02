#!/usr/bin/env node
/**
 * Report and optionally repair household lifecycle drift (dry-run by default).
 *
 * Usage:
 *   node server/scripts/reconcileHouseholds.js           # report only
 *   node server/scripts/reconcileHouseholds.js --apply   # repair in one transaction
 */
import { createAppPool } from '../lib/db/createPool.js';
import { withTransaction } from '../lib/db/withTransaction.js';
import { closeHousehold, removePetFromHousehold } from '../lib/households/departure/index.js';
import { pickHouseholdSuccessor } from '../lib/households/erasure/index.js';
import { HOUSEHOLD_TIER_FULL } from '../lib/households/constants.js';
import { repointRemainingHouseholdDirectoryContacts } from '../lib/households/departure/contactRepoint.js';

const apply = process.argv.includes('--apply');

async function findHouseholdsWithoutOrganiser(client) {
  const result = await client.query(
    `SELECT h.id, h.name
     FROM households h
     WHERE NOT EXISTS (
       SELECT 1 FROM household_members hm
       WHERE hm.household_id = h.id AND hm.is_organiser = true
     )`,
  );
  return result.rows;
}

async function findEmptyMemberHouseholds(client) {
  const result = await client.query(
    `SELECT h.id, h.name
     FROM households h
     WHERE NOT EXISTS (
       SELECT 1 FROM household_members hm WHERE hm.household_id = h.id
     )`,
  );
  return result.rows;
}

async function findPetsWithNonMemberOwners(client) {
  const result = await client.query(
    `SELECT hp.household_id, hp.pet_id, p.user_id AS owner_user_id, h.name AS household_name
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     INNER JOIN households h ON h.id = hp.household_id
     WHERE NOT EXISTS (
       SELECT 1 FROM household_members hm
       WHERE hm.household_id = hp.household_id AND hm.user_id = p.user_id
     )`,
  );
  return result.rows;
}

async function findStaleHouseholdContactReferences(client) {
  const result = await client.query(
    `SELECT DISTINCT hp.household_id, h.name AS household_name, p.id AS pet_id, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN households h ON h.id = hp.household_id
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE EXISTS (
       SELECT 1 FROM pet_contact_relationships pcr
       INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
       INNER JOIN people_directories pd ON pd.id = pc.directory_id
       WHERE pcr.pet_id = p.id AND pd.household_id = hp.household_id
     )
     OR EXISTS (
       SELECT 1 FROM health_entries he
       INNER JOIN people_contacts pc ON pc.id = he.provider_contact_id
       INNER JOIN people_directories pd ON pd.id = pc.directory_id
       WHERE he.pet_id = p.id AND pd.household_id = hp.household_id
     )
     UNION
     SELECT DISTINCT pd.household_id, h.name, p.id, p.user_id
     FROM people_directories pd
     INNER JOIN households h ON h.id = pd.household_id
     INNER JOIN people_contacts pc ON pc.directory_id = pd.id
     INNER JOIN pet_contact_relationships pcr ON pcr.contact_id = pc.id
     INNER JOIN pets p ON p.id = pcr.pet_id
     LEFT JOIN household_pets hp ON hp.pet_id = p.id AND hp.household_id = pd.household_id
     WHERE hp.pet_id IS NULL`,
  );
  return result.rows;
}

async function repairOrganiserlessHouseholds(client, rows) {
  for (const row of rows) {
    const memberCount = await client.query(
      'SELECT count(*)::int AS c FROM household_members WHERE household_id = $1',
      [row.id],
    );
    if (memberCount.rows[0].c === 0) {
      await closeHousehold(client, row.id);
      continue;
    }
    const successorId = await pickHouseholdSuccessor(client, row.id);
    if (!successorId) continue;
    await client.query(
      `UPDATE household_members
       SET is_organiser = true, access_tier = $3, joined_at = joined_at
       WHERE household_id = $1 AND user_id = $2`,
      [row.id, successorId, HOUSEHOLD_TIER_FULL],
    );
  }
}

async function repairNonMemberPets(client, rows) {
  for (const row of rows) {
    await removePetFromHousehold(client, {
      householdId: row.household_id,
      petId: row.pet_id,
      ownerUserId: row.owner_user_id,
      copyToUserId: row.owner_user_id,
    });
  }
}

async function repairStaleContactHouseholds(client, staleRows) {
  const householdIds = [...new Set(staleRows.map((r) => r.household_id).filter(Boolean))];
  for (const householdId of householdIds) {
    await repointRemainingHouseholdDirectoryContacts(client, householdId);
  }
}

async function runReport(client) {
  const withoutOrganiser = await findHouseholdsWithoutOrganiser(client);
  const emptyMembers = await findEmptyMemberHouseholds(client);
  const nonMemberPets = await findPetsWithNonMemberOwners(client);
  const staleContacts = await findStaleHouseholdContactReferences(client);
  return {
    withoutOrganiser,
    emptyMembers,
    nonMemberPets,
    staleContacts,
  };
}

async function main() {
  const pool = createAppPool();
  try {
    let report;
    if (apply) {
      report = await withTransaction(pool, async (client) => {
        const snapshot = await runReport(client);
        await repairOrganiserlessHouseholds(client, snapshot.withoutOrganiser);
        for (const row of snapshot.emptyMembers) {
          await closeHousehold(client, row.id);
        }
        await repairNonMemberPets(client, snapshot.nonMemberPets);
        await repairStaleContactHouseholds(client, snapshot.staleContacts);
        return snapshot;
      });
    } else {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');
        report = await runReport(client);
        await client.query('ROLLBACK');
      } finally {
        client.release();
      }
    }

    console.log(JSON.stringify({
      mode: apply ? 'apply' : 'dry-run',
      households_without_organiser: report.withoutOrganiser,
      empty_households: report.emptyMembers,
      pets_owner_not_member: report.nonMemberPets,
      stale_household_contact_refs: report.staleContacts,
    }, null, 2));

    if (!apply && (
      report.withoutOrganiser.length
      || report.emptyMembers.length
      || report.nonMemberPets.length
      || report.staleContacts.length
    )) {
      process.exitCode = 2;
    }
  } catch (err) {
    console.error(err);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

main();
