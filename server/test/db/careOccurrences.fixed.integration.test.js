/**
 * Fixed schedule, stack, next-date choice, care tick — against PostgreSQL.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { runCareTick } from '../../lib/care/occurrence/index.js';
import {
  careApi,
  createOwner,
  invariantViolations,
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

const twiceDaily = (due) => ({
  care_family: 'medication', frequency: 'daily', next_due_date: due, schedule_times: ['08:00', '18:00'], name: 'Apoquel',
});

async function created(body, clock) {
  const res = await api.at(clock).create(body);
  expect(res.statusCode).toBe(201);
  return res.body;
}

const slots = (entry) => entry.open_occurrences.map((o) => `${o.scheduled_date} ${o.scheduled_time ?? '--'} ${o.status}`);

async function tick(clock) {
  const [todayIso, time] = clock.split('T');
  return runCareTick(harness.pool, { clock: { todayIso, nowTimeIso: time } });
}

describe('fixed schedule (D-CSM-023)', () => {
  it('FX-1 twice daily stores today and tomorrow', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    expect(entry.recurrence_anchor).toBe('from_due_date');
    expect(entry.schedule_anchor_date).toBe('2026-06-05');
    expect(slots(entry)).toEqual([
      '2026-06-05 08:00 due', '2026-06-05 18:00 due',
      '2026-06-06 08:00 coming_up', '2026-06-06 18:00 coming_up',
    ]);
  });

  it('FX-2 / FX-3 overdue until the next dose, then not recorded', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const noon = await api.at('2026-06-05T12:00').get(entry.id);
    expect(noon.body.open_occurrences[0].status).toBe('overdue');
    const evening = await api.at('2026-06-05T18:01').get(entry.id);
    expect(evening.body.open_occurrences.slice(0, 2).map((o) => o.status)).toEqual(['not_recorded', 'overdue']);
  });

  it('FX-4 / FX-5 the stack keeps three days, older doses close as not recorded', async () => {
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await tick('2026-06-03T12:00');
    const wed = await api.at('2026-06-03T12:00').get(entry.id);
    expect(wed.body.open_occurrences.filter((o) => o.status === 'not_recorded')).toHaveLength(4);
    await tick('2026-06-05T12:00');
    const rows = await occurrenceRows(harness.pool, entry.id);
    const closed = rows.filter((r) => r.status === 'not_recorded');
    expect(closed.map((r) => `${r.date} ${r.time}`)).toEqual(['2026-06-01 08:00', '2026-06-01 18:00']);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('FX-6 a closed not recorded dose can be recorded as given', async () => {
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await tick('2026-06-06T09:00');
    const rows = await occurrenceRows(harness.pool, entry.id);
    const old = rows.find((r) => r.status === 'not_recorded');
    const res = await api.at('2026-06-06T09:00').record(entry.id, old.id);
    expect(res.statusCode).toBe(200);
    expect(res.body.occurrence.status).toBe('completed');
    await tick('2026-06-06T10:00');
    const after = (await occurrenceRows(harness.pool, entry.id)).find((r) => r.id === old.id);
    expect(after.status).toBe('completed');
  });

  it('FX-6b a closed not recorded dose can be confirmed as skipped', async () => {
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await tick('2026-06-06T09:00');
    const rows = await occurrenceRows(harness.pool, entry.id);
    const old = rows.find((r) => r.status === 'not_recorded');
    const res = await api.at('2026-06-06T09:00').confirmSkip(entry.id, old.id);
    expect(res.statusCode).toBe(200);
    expect(res.body.occurrence).toMatchObject({ status: 'skipped', outcome: 'skipped' });
    const after = (await occurrenceRows(harness.pool, entry.id)).find((r) => r.id === old.id);
    expect(after).toMatchObject({ status: 'skipped' });
  });

  it('FX-9 monthly injection not logged keeps one overdue head and next month slot', async () => {
    const entry = await created({
      care_family: 'medication', frequency: 'monthly', next_due_date: '2026-06-03', name: 'Injection',
    }, '2026-06-03T07:00');
    await tick('2026-06-10T09:00');
    const read = await api.at('2026-06-10T09:00').get(entry.id);
    const open = read.body.open_occurrences;
    expect(open.filter((o) => ['overdue', 'not_recorded'].includes(o.status))).toHaveLength(1);
    expect(open.map((o) => o.scheduled_date)).toEqual(
      expect.arrayContaining(['2026-06-03', '2026-07-03']),
    );
  });

  it('FX-11 repeat end date stops new slots and the item can finish', async () => {
    const entry = await created({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-08',
      schedule_times: ['08:00'], repeat_end_date: '2026-06-10', name: 'Short course',
    }, '2026-06-08T07:00');
    await tick('2026-06-12T09:00');
    const read = await api.at('2026-06-12T09:00').get(entry.id);
    expect(read.body.open_occurrences.every((o) => o.scheduled_date <= '2026-06-10')).toBe(true);
    for (const occ of [...read.body.open_occurrences]) {
      await api.at('2026-06-12T10:00').skip(entry.id, occ.id);
    }
    const finished = await api.at('2026-06-12T10:01').get(entry.id);
    expect(finished.body.open_occurrences).toEqual([]);
  });

  it('FX-12 bulk stack: complete one slot and skip another', async () => {
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    const read = await api.at('2026-06-02T19:00').get(entry.id);
    const stack = read.body.open_occurrences.filter((o) => o.status === 'not_recorded');
    const done = await api.at('2026-06-02T19:00').complete(entry.id, stack[0].id, {
      completed_on: stack[0].scheduled_date,
    });
    expect(done.statusCode).toBe(200);
    const skipped = await api.at('2026-06-02T19:00').skip(entry.id, stack[1].id);
    expect(skipped.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === stack[0].id)).toMatchObject({ status: 'completed', completed_on: '2026-06-01' });
    expect(rows.find((r) => r.id === stack[1].id)).toMatchObject({ status: 'skipped' });
  });

  it('ME-1 a monthly schedule anchored on the 31st clamps to month ends', async () => {
    const entry = await created({
      care_family: 'weight_monitoring', recurrence_anchor: 'from_due_date', frequency: 'monthly', next_due_date: '2027-01-31',
    }, '2027-01-31T09:00');
    const done = await api.at('2027-01-31T10:00').skip(entry.id, entry.open_occurrences[0].id);
    expect(done.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2027-02-28']);
    await tick('2027-03-01T09:00');
    const read = await api.at('2027-03-01T09:00').get(entry.id);
    expect(read.body.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2027-02-28', '2027-03-31']);
  });
});

describe('next-date choice (D-CSM-026)', () => {
  const weeklyMonday = { care_family: 'medication', frequency: 'weekly', next_due_date: '2026-06-01', name: 'Injection' };

  it('FX-7 done two days late does not ask', async () => {
    const entry = await created(weeklyMonday, '2026-06-01T07:00');
    const res = await api.at('2026-06-03T09:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(res.statusCode).toBe(200);
  });

  it('FX-8 done on Saturday keeps the next date unless a choice is sent (D-CSM-026 v4)', async () => {
    const kept = await created(weeklyMonday, '2026-06-01T07:00');
    const keep = await api.at('2026-06-06T09:00').complete(kept.id, kept.open_occurrences[0].id, {});
    expect(keep.statusCode).toBe(200);
    expect(keep.body.next_choice_applied).toBe('keep');
    expect(keep.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-08']);

    const entry = await created(weeklyMonday, '2026-06-01T07:00');
    const moved = await api.at('2026-06-06T09:00').complete(entry.id, entry.open_occurrences[0].id, {
      next_choice: 'shift_following',
    });
    expect(moved.statusCode).toBe(200);
    expect(moved.body.entry.schedule_anchor_date).toBe('2026-06-06');
    expect(moved.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-13']);
  });

  it('LC-1 a remembered choice is applied without asking', async () => {
    const entry = await created(weeklyMonday, '2026-06-01T07:00');
    const res = await api.at('2026-06-06T09:00').complete(entry.id, entry.open_occurrences[0].id, {
      next_choice: 'skip_next', remember_choice: true,
    });
    expect(res.body.entry.late_completion_choice).toBe('skip_next');
    expect(res.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-15']);
    const later = res.body.entry.open_occurrences[0];
    const again = await api.at('2026-06-20T09:00').complete(entry.id, later.id, {});
    expect(again.statusCode).toBe(200);
    expect(again.body.next_choice_applied).toBe('skip_next');
  });

  it('LC-3 twice daily recorded at 15:00 with no choice keeps the 18:00 dose', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const [morning, evening] = entry.open_occurrences;
    const res = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, {});
    expect(res.statusCode).toBe(200);
    expect(res.body.next_choice_applied).toBe('keep');
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === morning.id).status).toBe('completed');
    expect(rows.find((r) => r.id === evening.id).status).toBe('pending');
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('LC-3b a remembered choice that does not fit this case falls back to keep', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    await harness.pool.query(
      "UPDATE health_entries SET late_completion_choice = 'shift_following' WHERE id = $1",
      [entry.id],
    );
    const [morning, evening] = entry.open_occurrences;
    const res = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, {});
    expect(res.statusCode).toBe(200);
    expect(res.body.next_choice_applied).toBe('keep');
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === evening.id).status).toBe('pending');
  });

  it('LC-3c an explicit choice that does not fit this case is refused and saves nothing', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const morning = entry.open_occurrences[0];
    const res = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, { next_choice: 'shift_following' });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('next_choice_not_available');
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === morning.id).status).toBe('pending');
  });

  it('LC-4 skip next is undone as a whole', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const [morning, evening] = entry.open_occurrences;
    const done = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, { next_choice: 'skip_next' });
    expect(done.statusCode).toBe(200);
    let rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === evening.id).status).toBe('skipped');
    await api.at('2026-06-05T15:01').undo(entry.id, { undo_token: done.body.undo_token });
    rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === morning.id).status).toBe('pending');
    expect(rows.find((r) => r.id === evening.id).status).toBe('pending');
  });

  it('UN-3 FX dose done then undo reopens the slot only', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const morning = entry.open_occurrences[0];
    const done = await api.at('2026-06-05T09:00').complete(entry.id, morning.id, {});
    expect(done.statusCode).toBe(200);
    const undone = await api.at('2026-06-05T09:01').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undone.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === morning.id).status).toBe('pending');
    expect(done.body.entry.open_occurrences.length).toBeGreaterThanOrEqual(1);
    expect(undone.body.entry.open_occurrences.some((o) => o.id === morning.id)).toBe(true);
  });
});

describe('change date, postpone, type switch', () => {
  it('this date only keeps the series; this and following moves it', async () => {
    const entry = await created({ care_family: 'medication', frequency: 'weekly', next_due_date: '2026-06-08' }, '2026-06-01T07:00');
    const only = await api.at('2026-06-01T07:00').reschedule(entry.id, entry.open_occurrences[0].id, { scheduled_date: '2026-06-10' });
    expect(only.statusCode).toBe(200);
    expect(only.body.entry.open_occurrences).toEqual([
      expect.objectContaining({ scheduled_date: '2026-06-10', origin: 'planned' }),
    ]);
    const done = await api.at('2026-06-10T09:00').complete(entry.id, only.body.entry.open_occurrences[0].id, {});
    expect(done.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-15']);
    const following = await api.at('2026-06-10T09:00').reschedule(entry.id, done.body.entry.open_occurrences[0].id, {
      scheduled_date: '2026-06-17', scope: 'following',
    });
    expect(following.body.entry.schedule_anchor_date).toBe('2026-06-17');
    expect(following.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-17']);
  });

  it('PP-3 postponing a fixed schedule pauses until the date, then the tick resumes it', async () => {
    const entry = await created({ care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-05' }, '2026-06-05T07:00');
    const res = await api.at('2026-06-05T07:00').postpone(entry.id, { until: '2026-06-10' });
    expect(res.body.entry.status).toBe('paused');
    expect(res.body.entry.paused_until).toBe('2026-06-10');
    await tick('2026-06-10T06:00');
    const read = await api.at('2026-06-10T06:00').get(entry.id);
    expect(read.body.status).toBe('active');
    expect(read.body.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-10', '2026-06-11']);
  });

  it('PP-4 FX pause resume defaults to the first slot on or after now', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    await api.at('2026-06-10T09:00').postpone(entry.id, { until: null });
    const paused = await api.at('2026-06-19T09:00').get(entry.id);
    expect(paused.body.status).toBe('paused');
    expect(paused.body.resume_default_date).toBe('2026-06-19');
    const resumed = await api.at('2026-06-20T08:00').resume(entry.id, {});
    expect(resumed.statusCode).toBe(200);
    const firstSlot = resumed.body.entry.open_occurrences[0];
    expect(firstSlot.scheduled_date).toBe('2026-06-20');
    expect(['due', 'coming_up', 'pending']).toContain(firstSlot.status);
  });

  it('PL-7 FX planned extra one-off dose is independent planned', async () => {
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const res = await api.at('2026-06-05T10:00').plan(entry.id, { scheduled_date: '2026-06-07' });
    expect([200, 201]).toContain(res.statusCode);
    const entryBody = res.body.entry ?? res.body;
    const extra = entryBody.open_occurrences.find((o) => o.scheduled_date === '2026-06-07');
    expect(extra).toMatchObject({ origin: 'planned', status: 'coming_up' });
    expect(entryBody.open_occurrences.filter((o) => o.scheduled_date === '2026-06-05')).toHaveLength(2);
  });

  it('TS-1 switching to after it\'s done closes the stack and computes from the last dose', async () => {
    const entry = await created({ care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', name: 'Switch' }, '2026-06-01T07:00');
    await api.at('2026-06-01T09:00').complete(entry.id, entry.open_occurrences[0].id, {});
    const res = await api.at('2026-06-03T09:00').put(entry.id, {
      name: 'Switch', care_family: 'medication', frequency: 'daily', recurrence_anchor: 'from_completion',
      next_due_date: '2026-06-02',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.open_occurrences).toEqual([
      expect.objectContaining({ scheduled_date: '2026-06-02', origin: 'computed', status: 'overdue' }),
    ]);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => r.status === 'not_recorded').length).toBeGreaterThan(0);
  });
});

describe('care tick (D-CSM-031)', () => {
  it('CR-1 overlapping ticks never duplicate slots', async () => {
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await Promise.all([tick('2026-06-02T09:00'), tick('2026-06-02T09:00'), tick('2026-06-02T09:00')]);
    const rows = await occurrenceRows(harness.pool, entry.id);
    const keys = rows.map((r) => `${r.date} ${r.time}`);
    expect(new Set(keys).size).toBe(keys.length);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-7 running the tick twice at the same moment is idempotent', async () => {
    const entry = await created(twiceDaily('2026-10-20'), '2026-10-20T07:00');
    await tick('2026-10-25T02:30');
    const first = await occurrenceRows(harness.pool, entry.id);
    await tick('2026-10-25T02:30');
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual(first);
  });
});
