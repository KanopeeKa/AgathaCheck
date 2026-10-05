import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createDbPool } from './helpers/careHarness.js';
import {
  applyPeopleHouseholdNotesDown,
  applyPeopleHouseholdNotesMigration,
} from './helpers/peopleHouseholdNotesSql.js';

let pool;

beforeAll(async () => {
  pool = createDbPool();
  const ready = await pool.query(
    `SELECT 1 FROM information_schema.tables
     WHERE table_schema = 'public' AND table_name = 'households'`,
  );
  if (ready.rows.length === 0) {
    throw new Error('088 migration tests require migrated PostgreSQL');
  }
}, 30000);

afterAll(async () => {
  if (pool) await pool.end();
});

describe('089_people_household_notes migration (real PG)', () => {
  it('applies and rolls back cleanly', async () => {
    await applyPeopleHouseholdNotesDown(pool);
    await applyPeopleHouseholdNotesMigration(pool);

    const userId = randomUUID();
    const householdId = randomUUID();
    const directoryId = randomUUID();
    const contactId = randomUUID();

    await pool.query(
      'INSERT INTO users (id, email, password_hash, first_name, last_name) VALUES ($1, $2, $3, $4, $5)',
      [userId, `hh-note-${userId}@test.local`, 'hash', 'Note', 'Tester'],
    );
    await pool.query(
      'INSERT INTO households (id, name) VALUES ($1, $2)',
      [householdId, 'Note HH'],
    );
    await pool.query(
      'INSERT INTO people_directories (id, household_id) VALUES ($1, $2)',
      [directoryId, householdId],
    );
    await pool.query(
      `INSERT INTO people_contacts (id, directory_id, kind, name)
       VALUES ($1, $2, 'person', 'Groomer')`,
      [contactId, directoryId],
    );

    await pool.query(
      `INSERT INTO people_contact_household_notes (
         contact_id, household_id, note, updated_by_user_id
       ) VALUES ($1, $2, $3, $4)`,
      [contactId, householdId, 'Prefers morning slots', userId],
    );

    const row = await pool.query(
      'SELECT note FROM people_contact_household_notes WHERE contact_id = $1',
      [contactId],
    );
    expect(row.rows[0].note).toBe('Prefers morning slots');

    await applyPeopleHouseholdNotesDown(pool);
    const gone = await pool.query(
      `SELECT 1 FROM information_schema.tables
       WHERE table_schema = 'public' AND table_name = 'people_contact_household_notes'`,
    );
    expect(gone.rows.length).toBe(0);

    await applyPeopleHouseholdNotesMigration(pool);
  });
});
