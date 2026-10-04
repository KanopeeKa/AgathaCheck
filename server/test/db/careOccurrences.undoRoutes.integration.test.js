/**
 * Per-occurrence undo vs schedule/undo after multi-step commands (gap-close C3).
 * Keeps the compatibility route until the Flutter client migrates (D-CSM-033).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi,
  createOwner,
  invariantViolations,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool);
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

const flea = (due) => ({
  care_family: 'parasite_prevention', frequency: 'monthly', next_due_date: due, name: 'Flea',
});

async function created(body, clock) {
  const res = await api.at(clock).create(body);
  expect(res.statusCode).toBe(201);
  return res.body;
}

function openDates(entry) {
  return entry.open_occurrences.map((o) => `${o.scheduled_date}:${o.origin}:${o.status}`);
}

describe('undo route parity (C3)', () => {
  it('UL-1 schedule/undo and per-occurrence undo match after a completion', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const done = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    expect(done.statusCode).toBe(200);

    const viaSchedule = await api.at('2026-06-05T10:01').undo(entry.id, { undo_token: done.body.undo_token });
    expect(viaSchedule.statusCode).toBe(200);
    expect(viaSchedule.body.entry.open_occurrences.map((o) => o.id)).toEqual([occ.id]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);

    await api.at('2026-06-05T10:02').complete(entry.id, occ.id, {});
    const viaOccurrence = await api.at('2026-06-05T10:03').undoOccurrence(entry.id, occ.id);
    expect(viaOccurrence.statusCode).toBe(200);
    expect(viaOccurrence.body.id).toBe(occ.id);
    expect(viaOccurrence.body.status).toBe('pending');

    const refreshed = await api.at('2026-06-05T10:04').get(entry.id);
    expect(refreshed.body.open_occurrences.map((o) => o.id)).toEqual([occ.id]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('UL-2 after complete then reschedule, schedule/undo reverses the last command only', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const done = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    const next = done.body.entry.open_occurrences[0];
    await api.at('2026-06-05T10:01').reschedule(entry.id, next.id, { scheduled_date: '2026-07-10' });

    const undoneReschedule = await api.at('2026-06-05T10:02').undo(entry.id);
    expect(undoneReschedule.statusCode).toBe(200);
    expect(openDates(undoneReschedule.body.entry)).toEqual(['2026-07-05:computed:coming_up']);
    expect(undoneReschedule.body.entry.open_occurrences[0].scheduled_date).toBe('2026-07-05');

    const undoneCompletion = await api.at('2026-06-05T10:03').undoOccurrence(entry.id, occ.id);
    expect(undoneCompletion.statusCode).toBe(200);
    expect(undoneCompletion.body.id).toBe(occ.id);

    const finalEntry = await api.at('2026-06-05T10:04').get(entry.id);
    expect(finalEntry.body.open_occurrences.map((o) => o.id)).toEqual([occ.id]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });
});
