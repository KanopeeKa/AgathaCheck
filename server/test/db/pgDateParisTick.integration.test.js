/**
 * AC-TZ3: under Europe/Paris, care tick converges (no duplicate close/create loop).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { runCareTick } from '../../lib/care/occurrence/careTick.js';
import {
  careApi, createDbPool, createOwner, occurrenceRows, openHarness, removeOwner,
} from './helpers/careHarness.js';

const PARIS = 'Europe/Paris';
const CLOCK = { todayIso: '2026-10-04', nowTimeIso: '12:00' };

let harness;
const owners = [];

beforeAll(async () => {
  harness = await openHarness();
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    for (const owner of owners) await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

describe('PG DATE + tick under Europe/Paris', () => {
  it('AC-TZ3 second tick is 0/0 and Oct 1 doses stay open inside the window', async () => {
    const owner = await createOwner(harness.pool, { timeZone: PARIS });
    owners.push(owner);
    const api = careApi(harness.app, owner);
    const created = await api.at('2026-10-01T07:00').create({
      name: 'Doses',
      care_family: 'medication',
      frequency: 'daily',
      next_due_date: '2026-10-01',
      schedule_times: ['08:00', '18:00'],
    });
    expect(created.statusCode).toBe(201);
    const entryId = created.body.id;

    const ledgerBefore = (await harness.pool.query(
      `SELECT COUNT(*)::int AS n FROM care_schedule_events WHERE health_entry_id = $1`,
      [entryId],
    )).rows[0].n;

    const first = await runCareTick(harness.pool, { clock: CLOCK });
    expect(first.skipped).toBe(false);

    const second = await runCareTick(harness.pool, { clock: CLOCK });
    expect(second).toMatchObject({ skipped: false, created: 0, closed: 0 });

    const ledgerAfter = (await harness.pool.query(
      `SELECT COUNT(*)::int AS n FROM care_schedule_events WHERE health_entry_id = $1`,
      [entryId],
    )).rows[0].n;
    expect(ledgerAfter).toBe(ledgerBefore);

    const rows = await occurrenceRows(harness.pool, entryId);
    const oct1Pending = rows.filter((r) => r.date === '2026-10-01' && r.status === 'pending');
    expect(oct1Pending.length).toBeGreaterThanOrEqual(2);
    const dupes = rows.filter((r) => r.date === '2026-10-01' && r.time === '08:00');
    expect(dupes.length).toBeLessThanOrEqual(2);
  });
});
