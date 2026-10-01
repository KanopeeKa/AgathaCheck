/**
 * UAT care dataset (care-next-occurrence-c1a7 §6.4): every row, built through
 * the care commands, with the seed clock pinned so the dataset is identical
 * whatever the time of day.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { DEMO_IDS } from '../../../db/seeds/demo-constants.js';
import { careOccurrencesSeedFacts, seedCareOccurrences } from '../../../db/seeds/scenarios/care-occurrences.js';
import { seedGuardian } from '../../../db/seeds/scenarios/guardian.js';
import { dateToIsoDate } from '../../../lib/calendarDate.js';
import { careItemReadAdditions, listOpenRows } from '../../../lib/care/occurrence/index.js';
import { createDbPool } from '../helpers/careHarness.js';

const CLOCK = { todayIso: '2026-06-10', nowTimeIso: '15:00', timeZone: 'Europe/Paris' };
let pool;
let client;
let dbReady = false;

async function item(id) {
  const entry = (await client.query('SELECT * FROM health_entries WHERE id = $1', [id])).rows[0];
  const rows = await listOpenRows(client, id);
  return { entry, ...careItemReadAdditions(entry, rows, CLOCK) };
}

const view = (it) => it.open_occurrences.map((o) => `${o.scheduled_date} ${o.scheduled_time ?? '--'} ${o.status} ${o.origin}`);

beforeAll(async () => {
  pool = createDbPool();
  try {
    const ready = await pool.query(
      "SELECT 1 FROM information_schema.columns WHERE table_name = 'health_occurrences' AND column_name = 'origin'",
    );
    if (ready.rows.length === 0) return;
  } catch {
    // No PostgreSQL in this job (unit CI): the DB suite runs in the
    // "Backend integration (PostgreSQL)" job.
    return;
  }
  client = await pool.connect();
  await client.query('BEGIN');
  process.env.SEED_CARE_CLOCK = `${CLOCK.todayIso}T${CLOCK.nowTimeIso}`;
  await seedGuardian(client);
  await seedCareOccurrences(client);
  await seedCareOccurrences(client);
  dbReady = true;
}, 60000);

afterAll(async () => {
  delete process.env.SEED_CARE_CLOCK;
  if (client) {
    await client.query('ROLLBACK').catch(() => {});
    client.release();
  }
  await pool?.end();
});

describe('care occurrences seed (Buddy)', () => {
  const ids = careOccurrencesSeedFacts().buddy;

  it('Apoquel: one dose not recorded, this morning overdue, evening due', async () => {
    if (!dbReady) return;
    const apoquel = await item(ids.apoquel);
    expect(apoquel.entry.recurrence_anchor).toBe('from_due_date');
    expect(view(apoquel)).toEqual([
      '2026-06-09 18:00 not_recorded schedule',
      '2026-06-10 08:00 overdue schedule',
      '2026-06-10 18:00 due schedule',
      '2026-06-11 08:00 coming_up schedule',
      '2026-06-11 18:00 coming_up schedule',
    ]);
  });

  it('Heart tablet remembers "Skip the next date"', async () => {
    if (!dbReady) return;
    const heart = await item(ids.heartTablet);
    expect(heart.late_completion_choice).toBe('skip_next');
  });

  it('NexGard is due soon; Rabies far ahead; DHPP booster planned', async () => {
    if (!dbReady) return;
    expect(view(await item(ids.nexgard))).toEqual(['2026-06-13 -- coming_up computed']);
    expect(view(await item(ids.rabies))).toEqual(['2026-12-27 -- coming_up computed']);
    expect(view(await item(ids.dhpp))).toEqual(['2026-06-20 -- coming_up planned']);
  });

  it('Wellness review is overdue with an estimated next date', async () => {
    if (!dbReady) return;
    const wellness = await item(ids.wellness);
    expect(view(wellness)).toEqual(['2026-06-05 -- overdue computed']);
    expect(wellness.estimated_next).toEqual({ date: '2027-06-10', basis: 'done_today' });
  });

  it('Dental chew is due today with no time; Grooming is paused', async () => {
    if (!dbReady) return;
    expect(view(await item(ids.dentalChew))).toEqual(['2026-06-10 -- due computed']);
    const grooming = await item(ids.grooming);
    expect(grooming.entry.status).toBe('paused');
    expect(grooming.resume_default_date).toBeTruthy();
  });
});

describe('care occurrences seed (Whiskers)', () => {
  const ids = careOccurrencesSeedFacts().whiskers;

  it('Methimazole: six doses not recorded, one older dose closed as not recorded', async () => {
    if (!dbReady) return;
    const meth = await item(ids.methimazole);
    expect(meth.open_occurrences.filter((o) => o.status === 'not_recorded')).toHaveLength(6);
    const closed = await client.query(
      `SELECT to_char(scheduled_date, 'YYYY-MM-DD') AS d, to_char(scheduled_time, 'HH24:MI') AS t
       FROM health_occurrences WHERE health_entry_id = $1 AND close_reason = 'not_recorded'`,
      [ids.methimazole],
    );
    expect(closed.rows).toEqual([{ d: '2026-06-06', t: '20:00' }]);
  });

  it('Flea at 19:00 today, nail trim tomorrow, vaccination in 90 days', async () => {
    if (!dbReady) return;
    expect(view(await item(ids.flea))).toEqual(['2026-06-10 19:00 due computed']);
    expect(view(await item(ids.nailTrim))).toEqual(['2026-06-11 -- coming_up computed']);
    expect(view(await item(ids.vaccination))).toEqual(['2026-09-08 -- coming_up computed']);
  });

  it('Monthly weigh-in is a fixed schedule set explicitly, clamped to month ends', async () => {
    if (!dbReady) return;
    const weigh = await item(ids.weighIn);
    expect(weigh.entry.recurrence_anchor).toBe('from_due_date');
    expect(weigh.schedule_anchor_date).toBe('2026-05-31');
    expect(view(weigh)).toEqual(['2026-06-30 -- coming_up schedule']);
  });

  it('Vet visit is recorded only', async () => {
    if (!dbReady) return;
    const visit = await item(ids.vetVisit);
    expect(visit.entry.status).toBe('completed');
    expect(visit.open_occurrences).toEqual([]);
  });
});

describe('care occurrences seed invariants', () => {
  it('INV-1, INV-2, INV-5 hold for every seeded item, and seeding twice is idempotent', async () => {
    if (!dbReady) return;
    const all = [...Object.values(careOccurrencesSeedFacts().buddy), ...Object.values(careOccurrencesSeedFacts().whiskers)];
    for (const id of all) {
      const { entry, open_occurrences: open } = await item(id);
      if (entry.status === 'active') expect(open.length).toBeGreaterThan(0);
      expect(open.filter((o) => o.origin === 'computed').length).toBeLessThanOrEqual(1);
      if (entry.status !== 'completed') {
        expect(dateToIsoDate(entry.next_due_date)).toBe(open[0]?.scheduled_date ?? null);
      }
    }
    const count = await client.query(
      'SELECT COUNT(*)::int AS n FROM health_entries WHERE pet_id = ANY($1::uuid[]) AND id = ANY($2::uuid[])',
      [[DEMO_IDS.buddyPet, DEMO_IDS.whiskersPet], all],
    );
    expect(count.rows[0].n).toBe(all.length);
  });
});
