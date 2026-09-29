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
  openHarness,
  removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) return;
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
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    expect(entry.recurrence_anchor).toBe('from_due_date');
    expect(entry.schedule_anchor_date).toBe('2026-06-05');
    expect(slots(entry)).toEqual([
      '2026-06-05 08:00 due', '2026-06-05 18:00 due',
      '2026-06-06 08:00 coming_up', '2026-06-06 18:00 coming_up',
    ]);
  });

  it('FX-2 / FX-3 overdue until the next dose, then not recorded', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const noon = await api.at('2026-06-05T12:00').get(entry.id);
    expect(noon.body.open_occurrences[0].status).toBe('overdue');
    const evening = await api.at('2026-06-05T18:01').get(entry.id);
    expect(evening.body.open_occurrences.slice(0, 2).map((o) => o.status)).toEqual(['not_recorded', 'overdue']);
  });

  it('FX-4 / FX-5 the stack keeps three days, older doses close as not recorded', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await tick('2026-06-03T12:00');
    const wed = await api.at('2026-06-03T12:00').get(entry.id);
    expect(wed.body.open_occurrences.filter((o) => o.status === 'not_recorded')).toHaveLength(4);
    await tick('2026-06-05T12:00');
    const rows = await occurrenceRows(harness.pool, entry.id);
    const closed = rows.filter((r) => r.close_reason === 'not_recorded');
    expect(closed.map((r) => `${r.date} ${r.time}`)).toEqual(['2026-06-01 08:00', '2026-06-01 18:00']);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('FX-6 a closed not recorded dose can be recorded as given', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await tick('2026-06-06T09:00');
    const rows = await occurrenceRows(harness.pool, entry.id);
    const old = rows.find((r) => r.close_reason === 'not_recorded');
    const res = await api.at('2026-06-06T09:00').record(entry.id, old.id);
    expect(res.statusCode).toBe(200);
    expect(res.body.occurrence.status).toBe('completed');
    await tick('2026-06-06T10:00');
    const after = (await occurrenceRows(harness.pool, entry.id)).find((r) => r.id === old.id);
    expect(after.status).toBe('completed');
  });

  it('FX-12 record earlier doses: given and not given', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    const read = await api.at('2026-06-02T19:00').get(entry.id);
    const stack = read.body.open_occurrences.filter((o) => o.status === 'not_recorded');
    const res = await api.at('2026-06-02T19:00').resolveStack(entry.id, {
      given: [stack[0].id], not_given: [stack[1].id],
    });
    expect(res.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === stack[0].id)).toMatchObject({ status: 'completed', completed_on: '2026-06-01' });
    expect(rows.find((r) => r.id === stack[1].id)).toMatchObject({ status: 'skipped', close_reason: 'user' });
  });

  it('ME-1 a monthly schedule anchored on the 31st clamps to month ends', async () => {
    if (!harness.pool) return;
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
    if (!harness.pool) return;
    const entry = await created(weeklyMonday, '2026-06-01T07:00');
    const res = await api.at('2026-06-03T09:00').complete(entry.id, entry.open_occurrences[0].id, {});
    expect(res.statusCode).toBe(200);
  });

  it('FX-8 done on Saturday asks, saves nothing, then moves the schedule', async () => {
    if (!harness.pool) return;
    const entry = await created(weeklyMonday, '2026-06-01T07:00');
    const first = entry.open_occurrences[0];
    const ask = await api.at('2026-06-06T09:00').complete(entry.id, first.id, {});
    expect(ask.statusCode).toBe(409);
    expect(ask.body).toMatchObject({ code: 'next_choice_required', shift: { days: 5 } });
    expect((await occurrenceRows(harness.pool, entry.id)).find((r) => r.id === first.id).status).toBe('pending');
    const moved = await api.at('2026-06-06T09:00').complete(entry.id, first.id, { next_choice: 'shift_following' });
    expect(moved.statusCode).toBe(200);
    expect(moved.body.entry.schedule_anchor_date).toBe('2026-06-06');
    expect(moved.body.entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-13']);
  });

  it('LC-1 a remembered choice is applied without asking', async () => {
    if (!harness.pool) return;
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

  it('LC-3 / LC-4 twice daily recorded at 15:00 asks; skip next is undone as a whole', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-05'), '2026-06-05T07:00');
    const morning = entry.open_occurrences[0];
    const ask = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, {});
    expect(ask.statusCode).toBe(409);
    expect(ask.body.options).toEqual(['keep', 'skip_next']);
    const done = await api.at('2026-06-05T15:00').complete(entry.id, morning.id, { next_choice: 'skip_next' });
    const evening = entry.open_occurrences[1];
    let rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === evening.id).status).toBe('skipped');
    await api.at('2026-06-05T15:01').undo(entry.id, { undo_token: done.body.undo_token });
    rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === morning.id).status).toBe('pending');
    expect(rows.find((r) => r.id === evening.id).status).toBe('pending');
  });
});

describe('change date, postpone, type switch', () => {
  it('this date only keeps the series; this and following moves it', async () => {
    if (!harness.pool) return;
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
    if (!harness.pool) return;
    const entry = await created({ care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-05' }, '2026-06-05T07:00');
    const res = await api.at('2026-06-05T07:00').postpone(entry.id, { until: '2026-06-10' });
    expect(res.body.entry.status).toBe('paused');
    expect(res.body.entry.paused_until).toBe('2026-06-10');
    await tick('2026-06-10T06:00');
    const read = await api.at('2026-06-10T06:00').get(entry.id);
    expect(read.body.status).toBe('active');
    expect(read.body.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-10', '2026-06-11']);
  });

  it('TS-1 switching to after it\'s done closes the stack and computes from the last dose', async () => {
    if (!harness.pool) return;
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
    expect(rows.filter((r) => r.close_reason === 'not_recorded').length).toBeGreaterThan(0);
  });
});

describe('care tick (D-CSM-031)', () => {
  it('CR-1 overlapping ticks never duplicate slots', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-06-01'), '2026-06-01T07:00');
    await Promise.all([tick('2026-06-02T09:00'), tick('2026-06-02T09:00'), tick('2026-06-02T09:00')]);
    const rows = await occurrenceRows(harness.pool, entry.id);
    const keys = rows.map((r) => `${r.date} ${r.time}`);
    expect(new Set(keys).size).toBe(keys.length);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('CR-7 running the tick twice at the same moment is idempotent', async () => {
    if (!harness.pool) return;
    const entry = await created(twiceDaily('2026-10-20'), '2026-10-20T07:00');
    await tick('2026-10-25T02:30');
    const first = await occurrenceRows(harness.pool, entry.id);
    await tick('2026-10-25T02:30');
    expect(await occurrenceRows(harness.pool, entry.id)).toEqual(first);
  });
});
