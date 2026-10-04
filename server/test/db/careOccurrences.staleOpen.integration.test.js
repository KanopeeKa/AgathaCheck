/**
 * Stale open doses outside the 3-day window (tick not run): reads and commands
 * must agree (not-recorded-stale-open bug).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi, createDbPool, createOwner, invariantViolations, occurrenceRows, openHarness, removeOwner,
} from './helpers/careHarness.js';

let harness;
const owners = [];

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) {
    const probe = createDbPool();
    try {
      await probe.query(
        `SELECT 1 FROM information_schema.columns
         WHERE table_name = 'health_occurrences' AND column_name = 'origin'`,
      );
      throw new Error('Care DB integration tests require the migrated health_occurrences.origin column');
    } finally {
      await probe.end();
    }
  }
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    for (const owner of owners) await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

function twiceDaily(start) {
  return {
    name: 'Doses',
    care_family: 'medication',
    frequency: 'daily',
    next_due_date: start,
    schedule_times: ['08:00', '18:00'],
  };
}

describe('stale open doses without tick', () => {
  it('NR-1 care item read commits catch-up and drops Sep 30 slots on Oct 4', async () => {
    const owner = await createOwner(harness.pool);
    owners.push(owner);
    const api = careApi(harness.app, owner);
    const created = await api.at('2026-09-30T07:00').create(twiceDaily('2026-09-30'));
    expect(created.statusCode).toBe(201);
    const entryId = created.body.id;
    const read = await api.at('2026-10-04T12:00').get(entryId);
    expect(read.statusCode).toBe(200);
    const openDates = read.body.open_occurrences.map((o) => o.scheduled_date);
    expect(openDates).not.toContain('2026-09-30');
    const rows = await occurrenceRows(harness.pool, entryId);
    expect(rows.filter((r) => r.date === '2026-09-30' && r.status === 'pending')).toHaveLength(0);
    expect(rows.filter((r) => r.date === '2026-09-30' && r.close_reason === 'not_recorded')).toHaveLength(2);
    expect(await invariantViolations(harness.pool, entryId)).toEqual([]);
  });

  it('NR-2 completing a dose closed by pre-sync stays closed (no rollback)', async () => {
    const owner = await createOwner(harness.pool);
    owners.push(owner);
    const api = careApi(harness.app, owner);
    const created = await api.at('2026-09-30T07:00').create(twiceDaily('2026-09-30'));
    const entryId = created.body.id;
    const morningId = (await occurrenceRows(harness.pool, entryId)).find(
      (r) => r.date === '2026-09-30' && r.time === '08:00',
    ).id;
    const res = await api.at('2026-10-04T12:00').complete(entryId, morningId, { completed_on: '2026-09-30' });
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('occurrence_not_open');
    const row = (await occurrenceRows(harness.pool, entryId)).find((r) => r.id === morningId);
    expect(row).toMatchObject({ status: 'skipped', close_reason: 'not_recorded' });
  });

  it('NR-3 resolve-stack ignores already-closed ids and completes the rest', async () => {
    const owner = await createOwner(harness.pool);
    owners.push(owner);
    const api = careApi(harness.app, owner);
    const created = await api.at('2026-06-01T07:00').create(twiceDaily('2026-06-01'));
    const entryId = created.body.id;
    const stack = (await api.at('2026-06-02T19:00').get(entryId)).body.open_occurrences
      .filter((o) => o.status === 'not_recorded');
    expect(stack.length).toBeGreaterThanOrEqual(2);
    const [first, second] = stack;
    await api.at('2026-06-02T19:00').skip(entryId, first.id);
    const partial = await api.at('2026-06-02T19:01').resolveStack(entryId, {
      given: [first.id, second.id],
      not_given: [],
    });
    expect(partial.statusCode).toBe(200);
    expect(partial.body.ignored).toEqual([first.id]);
    expect(partial.body.given).toEqual([second.id]);
    expect(await invariantViolations(harness.pool, entryId)).toEqual([]);
  });

  it('NR-4 resolve-stack with every id closed returns nothing_to_update', async () => {
    const owner = await createOwner(harness.pool);
    owners.push(owner);
    const api = careApi(harness.app, owner);
    const created = await api.at('2026-09-30T07:00').create(twiceDaily('2026-09-30'));
    const entryId = created.body.id;
    const slots = created.body.open_occurrences.filter((o) => o.scheduled_date === '2026-09-30');
    await api.at('2026-10-04T12:00').get(entryId);
    const res = await api.at('2026-10-04T12:01').resolveStack(entryId, {
      given: slots.map((o) => o.id),
      not_given: [],
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('nothing_to_update');
  });
});
