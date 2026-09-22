import { describe, expect, it, beforeAll } from '@jest/globals';
import pg from 'pg';
import { evaluateWeightEstablishment } from '../../../lib/care/progression/weightEstablishmentPolicy.js';
import { DEMO_IDS } from '../../../db/seeds/demo-constants.js';
import {
  careItemModelWeightEstablishmentFacts,
  seedCareItemModelFixture,
} from '../../../db/seeds/scenarios/care-item-model-fixture.js';
import { seedGuardian } from '../../../db/seeds/scenarios/guardian.js';

function createPool() {
  if (process.env.DATABASE_URL) {
    return new pg.Pool({ connectionString: process.env.DATABASE_URL });
  }
  return new pg.Pool({
    user: process.env.PGUSER || 'user',
    password: process.env.PGPASSWORD || 'password',
    host: process.env.PGHOST || 'localhost',
    port: process.env.PGPORT || 5432,
    database: process.env.PGDATABASE || 'agatha_db',
  });
}

const CARE_FIXTURE_ENTRY_IDS = [
  DEMO_IDS.careFixtureTodayPending,
  DEMO_IDS.careFixtureTodayDone,
  DEMO_IDS.careFixtureOneOffToday,
  DEMO_IDS.careFixtureUncategorised,
  DEMO_IDS.careFixtureUpcomingWeek,
  DEMO_IDS.careFixtureWeightEntry,
];

const CARE_FIXTURE_WEIGHT_OCC_IDS = [
  DEMO_IDS.careFixtureWeightOcc1,
  DEMO_IDS.careFixtureWeightOcc2,
  DEMO_IDS.careFixtureWeightOcc3,
  DEMO_IDS.careFixtureWeightOcc4,
];

async function countCareFixtureRows(client) {
  const entries = await client.query(
    `SELECT COUNT(*)::int AS count FROM health_entries WHERE id = ANY($1::uuid[])`,
    [CARE_FIXTURE_ENTRY_IDS],
  );
  const occurrences = await client.query(
    `SELECT COUNT(*)::int AS count FROM health_occurrences
     WHERE health_entry_id = $1 OR id = $2`,
    [DEMO_IDS.careFixtureWeightEntry, DEMO_IDS.careFixtureTodayDoneOcc],
  );
  const weightEntries = await client.query(
    `SELECT COUNT(*)::int AS count FROM weight_entries
     WHERE health_occurrence_id = ANY($1::uuid[])`,
    [CARE_FIXTURE_WEIGHT_OCC_IDS],
  );
  const establishments = await client.query(
    `SELECT COUNT(*)::int AS count FROM care_establishments WHERE health_entry_id = $1`,
    [DEMO_IDS.careFixtureWeightEntry],
  );
  const pets = await client.query(
    `SELECT COUNT(*)::int AS count FROM pets WHERE id = $1`,
    [DEMO_IDS.pebblePet],
  );
  return {
    entries: entries.rows[0].count,
    occurrences: occurrences.rows[0].count,
    weight_entries: weightEntries.rows[0].count,
    establishments: establishments.rows[0].count,
    pebble: pets.rows[0].count,
  };
}

describe('care-item-model-fixture seed facts', () => {
  it('reports established for the seeded weekly weight monitoring item', () => {
    const facts = careItemModelWeightEstablishmentFacts();
    const result = evaluateWeightEstablishment(
      DEMO_IDS.buddyPet,
      DEMO_IDS.careFixtureWeightEntry,
      facts,
    );
    expect(result.maturity).toBe('established');
    expect(result.reasonCodes).toContain('established');
    expect(facts.completedEvidence).toHaveLength(4);
  });
});

describe('care-item-model-fixture seed database rows (issue #1125)', () => {
  let dbAvailable = false;
  let pool;

  beforeAll(async () => {
    pool = createPool();
    try {
      await pool.query('SELECT 1');
      dbAvailable = true;
    } catch {
      dbAvailable = false;
      await pool.end();
      pool = null;
    }
  }, 30000);

  it('writes rows matching the facts helper and is idempotent', async () => {
    if (!dbAvailable || !pool) return;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await seedGuardian(client);
      await seedCareItemModelFixture(client);
      const first = await countCareFixtureRows(client);
      await seedCareItemModelFixture(client);
      const second = await countCareFixtureRows(client);
      await client.query('ROLLBACK');

      expect(first.entries).toBe(6);
      expect(first.occurrences).toBe(6);
      expect(first.weight_entries).toBe(4);
      expect(first.establishments).toBe(1);
      expect(first.pebble).toBe(1);
      expect(second).toEqual(first);
    } finally {
      client.release();
      await pool.end();
    }
  }, 60000);
});
