/**
 * After it's done, planned dates, postpone, undo — against PostgreSQL through
 * the real routes (occurrence-scheduling.md acceptance matrix).
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

describe('after it\'s done (D-CSM-022)', () => {
  it('defaults parasite prevention to After it\'s done and medication to Fixed schedule (D-CSM-020)', async () => {
    const aid = await created(flea('2026-06-05'), '2026-06-01T09:00');
    expect(aid.recurrence_anchor).toBe('from_completion');
    const med = await created({ care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01' }, '2026-06-01T09:00');
    expect(med.recurrence_anchor).toBe('from_due_date');
  });

  it('AID-1 marking done creates the next date in the same request', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const res = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    expect(res.statusCode).toBe(200);
    expect(res.body.next_due_date).toBe('2026-07-05');
    expect(openDates(res.body.entry)).toEqual(['2026-07-05:computed:coming_up']);
    expect(res.body.undo_token).toBeTruthy();
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('AID-2 overdue shows an estimated next date that moves with today', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const res = await api.at('2026-06-07T09:00').get(entry.id);
    expect(res.body.open_occurrences[0].status).toBe('overdue');
    expect(res.body.estimated_next).toEqual({ date: '2026-07-07', basis: 'done_today' });
  });

  it('AID-3 / AID-4 done or skipped late count from the done date or today', async () => {
    const a = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const done = await api.at('2026-06-07T09:00').complete(a.id, a.open_occurrences[0].id, { completed_on: '2026-06-06' });
    expect(done.body.next_due_date).toBe('2026-07-06');
    const b = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const skipped = await api.at('2026-06-07T09:00').skip(b.id, b.open_occurrences[0].id);
    expect(skipped.statusCode).toBe(200);
    expect(skipped.body.next_due_date).toBe('2026-07-07');
  });

  it('AID-8 several times of day need a fixed schedule', async () => {
    const res = await api.at('2026-06-01T09:00').create({
      ...flea('2026-06-05'), recurrence_anchor: 'from_completion', schedule_times: ['08:00', '18:00'],
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('times_require_fixed_schedule');
  });

  it('AID-9 a date 200 days away is a real occurrence that can be marked done early', async () => {
    const entry = await created({ care_family: 'vaccination', frequency: 'yearly', next_due_date: '2026-12-18' }, '2026-06-01T09:00');
    expect(openDates(entry)).toEqual(['2026-12-18:computed:coming_up']);
    const res = await api.at('2026-06-01T10:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(res.statusCode).toBe(200);
    expect(res.body.occurrence.completion_timing).toBe('early');
    expect(res.body.next_due_date).toBe('2027-06-01');
  });

  it('FM-3 planned care with a completed date is rejected', async () => {
    const res = await api.at('2026-06-01T09:00').create({ ...flea('2026-06-05'), completed_on: '2026-06-01' });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('completed_on_not_allowed');
  });
});

describe('planned dates (D-CSM-025, D-CSM-021)', () => {
  it('PL-1 a booster planned at create is next after the first dose, then the yearly rule', async () => {
    const entry = await created({
      care_family: 'vaccination', frequency: 'yearly', next_due_date: '2026-06-01', planned_dates: ['2026-07-01'],
    }, '2026-06-01T09:00');
    expect(openDates(entry)).toEqual(['2026-06-01:computed:due', '2026-07-01:planned:coming_up']);
    const first = await api.at('2026-06-01T10:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(openDates(first.body.entry)).toEqual(['2026-07-01:planned:coming_up']);
    const booster = first.body.entry.open_occurrences[0];
    const second = await api.at('2026-07-01T10:00').complete(entry.id, booster.id, {});
    expect(openDates(second.body.entry)).toEqual(['2027-07-01:computed:coming_up']);
  });

  it('PL-2 a late first dose keeps the booster unless a choice is sent (D-CSM-026 v4)', async () => {
    const booster = {
      care_family: 'vaccination', frequency: 'yearly', next_due_date: '2026-06-01', planned_dates: ['2026-07-01'],
    };
    const kept = await created(booster, '2026-06-01T09:00');
    const keep = await api.at('2026-06-20T09:00').complete(kept.id, kept.open_occurrences[0].id, {});
    expect(keep.statusCode).toBe(200);
    expect(keep.body.next_choice_applied).toBe('keep');
    expect(openDates(keep.body.entry)).toEqual(['2026-07-01:planned:coming_up']);

    const shifted = await created(booster, '2026-06-01T09:00');
    const moved = await api.at('2026-06-20T09:00').complete(shifted.id, shifted.open_occurrences[0].id, {
      next_choice: 'shift_following',
    });
    expect(moved.statusCode).toBe(200);
    expect(openDates(moved.body.entry)).toEqual(['2026-07-20:planned:coming_up']);
  });

  it('PL-3 changing the computed date keeps one occurrence, now planned', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const occ = entry.open_occurrences[0];
    const res = await api.at('2026-06-01T09:00').reschedule(entry.id, occ.id, { scheduled_date: '2026-06-20' });
    expect(res.statusCode).toBe(200);
    expect(res.body.entry.open_occurrences).toEqual([
      expect.objectContaining({ id: occ.id, scheduled_date: '2026-06-20', origin: 'planned' }),
    ]);
  });

  it('PL-4 planning another date near an open one warns and adds it', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const res = await api.at('2026-06-01T09:00').plan(entry.id, { scheduled_date: '2026-06-08' });
    expect(res.statusCode).toBe(201);
    expect(res.body.warnings).toEqual([{ code: 'another_date_near', scheduled_date: '2026-06-05' }]);
    expect(res.body.entry.open_occurrences).toHaveLength(2);
  });

  it('PL-5 / OR-3 marking the later date first keeps the earlier one open unless a choice is sent', async () => {
    const kept = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const plannedKept = await api.at('2026-06-01T09:00').plan(kept.id, { scheduled_date: '2026-07-01' });
    const laterKept = plannedKept.body.entry.open_occurrences.find((o) => o.scheduled_date === '2026-07-01');
    const keep = await api.at('2026-06-10T09:00').complete(kept.id, laterKept.id, {});
    expect(keep.statusCode).toBe(200);
    expect(openDates(keep.body.entry)).toEqual(['2026-06-05:computed:overdue']);
    expect(await invariantViolations(harness.pool, kept.id)).toEqual([]);

    const skipped = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const planned = await api.at('2026-06-01T09:00').plan(skipped.id, { scheduled_date: '2026-07-01' });
    const later = planned.body.entry.open_occurrences.find((o) => o.scheduled_date === '2026-07-01');
    const done = await api.at('2026-06-10T09:00').complete(skipped.id, later.id, { earlier_choice: 'skip' });
    expect(done.statusCode).toBe(200);
    expect(openDates(done.body.entry)).toEqual(['2026-07-10:computed:coming_up']);
    expect(await invariantViolations(harness.pool, skipped.id)).toEqual([]);
  });
});

describe('postpone, pause, resume (D-CSM-028)', () => {
  it('PP-1 postponing moves the date; done counts from the done date', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const res = await api.at('2026-06-01T09:00').postpone(entry.id, { until: '2026-06-20' });
    expect(res.statusCode).toBe(200);
    expect(openDates(res.body.entry)).toEqual(['2026-06-20:planned:coming_up']);
    const done = await api.at('2026-06-20T09:00').complete(entry.id, res.body.entry.open_occurrences[0].id, {});
    expect(done.body.next_due_date).toBe('2026-07-20');
  });

  it('PP-2 pause hides the item; resume defaults to the date it would have had', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const paused = await api.at('2026-06-01T09:00').postpone(entry.id, { until: null });
    expect(paused.body.entry.status).toBe('paused');
    const read = await api.at('2026-08-01T09:00').get(entry.id);
    expect(read.body.resume_default_date).toBe('2026-08-05');
    const resumed = await api.at('2026-08-01T09:00').resume(entry.id, { date: '2026-08-03' });
    expect(resumed.statusCode).toBe(200);
    expect(resumed.body.entry.status).toBe('active');
    expect(openDates(resumed.body.entry)).toEqual(['2026-08-03:planned:coming_up']);
  });

  it('PP-6 a past date is rejected', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const res = await api.at('2026-06-10T09:00').postpone(entry.id, { until: '2026-06-01' });
    expect(res.statusCode).toBe(400);
  });

  it('PP-7 undo right after pause restores the item', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    await api.at('2026-06-01T09:00').postpone(entry.id, { until: null });
    const undone = await api.at('2026-06-01T09:05').undo(entry.id);
    expect(undone.statusCode).toBe(200);
    expect(undone.body.entry.status).toBe('active');
  });
});

describe('undo (D-CSM-029)', () => {
  it('UN-1 undo reopens the date and removes the new computed date', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const done = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    const undone = await api.at('2026-06-05T10:01').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undone.statusCode).toBe(200);
    expect(undone.body.entry.open_occurrences.map((o) => o.id)).toEqual([occ.id]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('UN-2 a next date someone changed survives undo of the completion', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const done = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    const next = done.body.entry.open_occurrences[0];
    await api.at('2026-06-05T10:01').reschedule(entry.id, next.id, { scheduled_date: '2026-07-10' });
    const undone = await api.at('2026-06-05T10:02').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undone.statusCode).toBe(200);
    expect(openDates(undone.body.entry)).toEqual(['2026-06-05:computed:due', '2026-07-10:planned:coming_up']);
  });

  it('LC-5 completing a date twice answers 409 occurrence_not_open', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    const again = await api.at('2026-06-05T10:00').complete(entry.id, occ.id, {});
    expect(again.statusCode).toBe(409);
    expect(again.body.code).toBe('occurrence_not_open');
  });

  it('CR-4 two carers completing the same date: one 200, one 409', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const results = await Promise.all([
      api.at('2026-06-05T10:00').complete(entry.id, occ.id, {}),
      api.at('2026-06-05T10:00').complete(entry.id, occ.id, {}),
    ]);
    expect(results.map((r) => r.statusCode).sort()).toEqual([200, 409]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });
});

describe('lifecycle and compatibility routes', () => {
  it('once care finishes when done and gets a new date when reopened', async () => {
    const entry = await created({ care_family: 'other', frequency: 'once', next_due_date: '2026-06-05' }, '2026-06-01T09:00');
    expect(openDates(entry)).toEqual(['2026-06-05:planned:coming_up']);
    const done = await api.at('2026-06-05T09:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(done.body.entry.status).toBe('completed');
    const reopened = await api.at('2026-06-06T09:00').reopen(entry.id);
    expect(reopened.body.status).toBe('active');
    expect(reopened.body.open_occurrences).toHaveLength(1);
  });

  it('undoing the completion of one-off care makes it active again', async () => {
    const entry = await created({ care_family: 'other', frequency: 'once', next_due_date: '2026-06-05' }, '2026-06-01T09:00');
    const done = await api.at('2026-06-05T09:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(done.body.entry.status).toBe('completed');
    const undone = await api.at('2026-06-05T09:01').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undone.body.entry.status).toBe('active');
    expect(undone.body.entry.open_occurrences).toHaveLength(1);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('F7 reopening a closed series creates its next date at once', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const closed = await api.at('2026-06-01T09:00').close(entry.id);
    expect(closed.body.status).toBe('completed');
    expect(closed.body.open_occurrences).toEqual([]);
    const reopened = await api.at('2026-06-02T09:00').reopen(entry.id);
    expect(reopened.body.open_occurrences).toHaveLength(1);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('mark-taken and ensure-open never fail for an active planned item', async () => {
    const entry = await created({ care_family: 'wellness_review', frequency: 'yearly', next_due_date: '2027-03-01' }, '2026-06-01T09:00');
    const ensured = await api.at('2026-06-01T09:00').ensureOpen(entry.id);
    expect(ensured.statusCode).toBe(200);
    expect(ensured.body.created).toBe(false);
    const taken = await api.at('2026-06-01T09:00').markTaken(entry.id);
    expect(taken.statusCode).toBe(200);
    expect(taken.body.next_due_date).toBe('2027-06-01');
  });

  it('TS-4 editing the next date moves the open occurrence', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const res = await api.at('2026-06-01T09:00').put(entry.id, {
      name: 'Flea', care_family: 'parasite_prevention', frequency: 'monthly', next_due_date: '2026-06-12',
    });
    expect(res.statusCode).toBe(200);
    expect(openDates(res.body)).toEqual(['2026-06-12:planned:coming_up']);
  });
});
