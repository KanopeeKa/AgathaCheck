/**
 * Regression for legacy mark-taken on active items whose canonical occurrence
 * is missing, exercised through the real command route and PostgreSQL.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi,
  createOwner,
  openHarness,
  occurrenceRows,
  removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) {
    throw new Error('mark-taken materialisation integration test requires the migrated PostgreSQL test database');
  }
  owner = await createOwner(harness.pool);
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

async function createEntry(overrides = {}) {
  const res = await api.at('2026-09-30T10:00').create({
    care_family: 'parasite_prevention',
    frequency: 'daily',
    recurrence_anchor: 'from_completion',
    next_due_date: '2099-01-08',
    name: 'Joint supplement',
    ...overrides,
  });
  expect(res.statusCode).toBe(201);
  return res.body;
}

async function removeOpenRows(entryId) {
  await harness.pool.query(
    'DELETE FROM health_occurrences WHERE health_entry_id = $1',
    [entryId],
  );
}

describe('POST /api/health-entries/:id/mark-taken with no materialised occurrence', () => {
  it('materialises and completes the canonical deferred recurring head in the command route', async () => {
    const entry = await createEntry();
    await removeOpenRows(entry.id);

    const res = await api.at('2026-09-30T10:00').markTaken(entry.id, {
      completed_on: '2026-09-30',
    });

    expect(res.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows).toEqual(expect.arrayContaining([
      expect.objectContaining({
        date: '2099-01-08',
        status: 'completed',
        completed_on: '2026-09-30',
      }),
      expect.objectContaining({ date: '2026-10-01', status: 'pending' }),
    ]));
    expect(res.body.next_due_date).toBe('2026-10-01');
  });

  it.each([
    { startDate: null },
    { startDate: '2026-09-01' },
  ])('materialises the original one-off due date when start_date is $startDate', async ({ startDate }) => {
    const dueDate = '2026-10-15';
    const entry = await createEntry({
      care_family: 'other',
      frequency: 'once',
      recurrence_anchor: null,
      next_due_date: dueDate,
    });
    await harness.pool.query(
      'UPDATE health_entries SET start_date = $1 WHERE id = $2',
      [startDate, entry.id],
    );
    await removeOpenRows(entry.id);

    const res = await api.at('2026-09-30T10:00').markTaken(entry.id, {
      completed_on: '2026-09-30',
    });

    expect(res.statusCode).toBe(200);
    expect(res.body.status).toBe('completed');
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual([
      expect.objectContaining({
        date: dueDate,
        status: 'completed',
        completed_on: '2026-09-30',
      }),
    ]);
  });

  it('keeps paused items unmaterialised and returns the established 400 error', async () => {
    const entry = await createEntry();
    await harness.pool.query(
      `UPDATE health_entries SET status = 'paused' WHERE id = $1`,
      [entry.id],
    );
    await removeOpenRows(entry.id);

    const res = await api.at('2026-09-30T10:00').markTaken(entry.id, {
      completed_on: '2026-09-30',
    });

    expect(res.statusCode).toBe(400);
    expect(res.body.error).toBe('Care item is paused');
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual([]);
  });
});
