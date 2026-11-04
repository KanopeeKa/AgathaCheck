/**
 * CARE-STATUS-R-008 — pause / schedule reconciliation: started → Not recorded,
 * not-yet-due → removed (no ledger).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi,
  createOwner,
  occurrenceRows,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

async function ledger(entryId) {
  const { rows } = await harness.pool.query(
    `SELECT event_type, payload FROM care_schedule_events
     WHERE health_entry_id = $1 ORDER BY occurred_at, id`,
    [entryId],
  );
  return rows;
}

async function created(body, clock) {
  const res = await api.at(clock).create(body);
  expect(res.statusCode).toBe(201);
  return res.body;
}

const flea = (due) => ({
  name: 'Flea',
  care_family: 'parasite_prevention',
  frequency: 'monthly',
  next_due_date: due,
});

describe('CARE-STATUS-R-008 pause and schedule rule', () => {
  it('R-008-1 fixed pause until: started doses become Not recorded; future doses are removed', async () => {
    const entry = await created({
      care_family: 'medication',
      frequency: 'daily',
      next_due_date: '2026-06-03',
      schedule_times: ['08:00', '18:00'],
      name: 'Daily',
    }, '2026-06-05T15:00');
    const beforePause = await occurrenceRows(harness.pool, entry.id);
    const eveningPending = beforePause.find(
      (r) => r.date === '2026-06-05' && r.time === '18:00' && r.status === 'pending',
    );
    expect(eveningPending).toBeDefined();

    const res = await api.at('2026-06-05T15:00').postpone(entry.id, { until: '2026-06-10' });
    expect(res.statusCode).toBe(200);
    expect(res.body.entry.status).toBe('paused');

    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === eveningPending.id)).toBeUndefined();
    expect(rows.filter((r) => r.status === 'pending' && r.date < '2026-06-10')).toHaveLength(0);
    expect(rows.filter((r) => r.status === 'not_recorded' && r.date <= '2026-06-05').length)
      .toBeGreaterThan(0);

    const events = await ledger(entry.id);
    expect(events.some((e) => e.event_type === 'postponed')).toBe(true);
    expect(events.filter((e) => e.event_type === 'not_recorded_closed')).toHaveLength(0);
  });

  it('R-008-2 after-it\'s-done pause removes a dose that has not started yet', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const paused = await api.at('2026-06-01T09:00').postpone(entry.id, { until: null });
    expect(paused.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => r.status === 'pending')).toHaveLength(0);
    expect(rows).toHaveLength(0);
    expect((await ledger(entry.id)).filter((e) => e.event_type === 'not_recorded_closed')).toHaveLength(0);
  });

  it('R-008-3 undo after pause reactivates the item (PP-7)', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    await api.at('2026-06-01T09:00').postpone(entry.id, { until: null });
    const undone = await api.at('2026-06-01T09:05').undo(entry.id);
    expect(undone.statusCode).toBe(200);
    expect(undone.body.entry.status).toBe('active');
  });
});
