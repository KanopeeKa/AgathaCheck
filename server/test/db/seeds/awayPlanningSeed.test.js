import { describe, expect, it, beforeAll } from '@jest/globals';
import pg from 'pg';

import { DEMO_IDS } from '../../../db/seeds/demo-constants.js';
import { seedGuardian } from '../../../db/seeds/scenarios/guardian.js';
import {
  awayPlanningSeedFacts,
  countAwayPlanningSeedRows,
  seedAwayPlanning,
} from '../../../db/seeds/scenarios/away-planning.js';
import {
  COVERAGE_STATE_ALL_COMPLETED,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
} from '../../../lib/care/carePeriodCoverage.js';
import {
  CARER_COVERAGE_ALL_HAVE_CARERS,
  CARER_COVERAGE_NONE_HAVE_CARERS,
  CARER_COVERAGE_SOME_HAVE_CARERS,
} from '../../../lib/care/awayPlan/readiness.js';

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

describe('away-planning seed facts', () => {
  it('documents AW-SEED coverage matrix intents', () => {
    const facts = awayPlanningSeedFacts();
    expect(facts.coverage_states).toHaveLength(5);
    expect(facts.carer_mix_states).toEqual([
      CARER_COVERAGE_ALL_HAVE_CARERS,
      CARER_COVERAGE_SOME_HAVE_CARERS,
      CARER_COVERAGE_NONE_HAVE_CARERS,
    ]);
    expect(facts.absences.upcomingCarerMix.carer_mix).toBe(CARER_COVERAGE_SOME_HAVE_CARERS);
    expect(facts.absences.activeMultiTime.multi_time_entry_id).toBe(DEMO_IDS.csmWeeklyCourse);
    expect(facts.absences.cancelled.lifecycle).toBe('cancelled');
    expect(facts.absences.futureNothingScheduled.coverage_state).toBe(
      COVERAGE_STATE_NOTHING_SCHEDULED,
    );
    expect(facts.absences.indeterminate.coverage_state).toBe(COVERAGE_STATE_INDETERMINATE);
    expect(facts.absences.noUnresolved.coverage_state).toBe(COVERAGE_STATE_NO_UNRESOLVED_ITEMS);
    expect(facts.absences.pastAllCompleted.coverage_state).toBe(COVERAGE_STATE_ALL_COMPLETED);
    expect(facts.absences.upcomingCarerMix.coverage_state).toBe(
      COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
    );
    expect(facts.absences.downloadedEdited.handover_downloaded_then_edited).toBe(true);
  });
});

describe('away-planning seed idempotency', () => {
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

  it('runs twice without changing seeded row counts', async () => {
    if (!dbAvailable || !pool) return;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await seedGuardian(client);
      await seedAwayPlanning(client);
      const first = await countAwayPlanningSeedRows(client);
      await seedAwayPlanning(client);
      const second = await countAwayPlanningSeedRows(client);
      await client.query('ROLLBACK');

      expect(first.absences).toBe(8);
      expect(first.pet_rows).toBeGreaterThanOrEqual(8);
      expect(second).toEqual(first);
    } finally {
      client.release();
      await pool.end();
    }
  }, 60000);
});
