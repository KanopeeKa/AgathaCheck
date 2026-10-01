/**
 * OR-4 property test: any sequence of care commands keeps INV-1 (an active
 * planned item always has an open occurrence), INV-2 (at most one computed)
 * and INV-5 (next_due_date = earliest open date).
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { runCareTick } from '../../lib/care/occurrence/index.js';
import { addDaysIso } from '../../lib/care/schedule/seriesDates.js';
import {
  careApi,
  createOwner,
  invariantViolations,
  occurrenceRows,
  openHarness,
  removeOwner,
} from './helpers/careHarness.js';

const STEPS = 520;

/** Deterministic PRNG (mulberry32) so failures reproduce. */
function rng(seed) {
  let a = seed;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

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

describe('care occurrence invariants under random commands (OR-4)', () => {
  it(`holds INV-1, INV-2, INV-5 over ${STEPS} random steps`, async () => {
    if (!harness.pool) return;
    const random = rng(Number(process.env.CARE_PROPERTY_SEED || 20260929));
    const pick = (list) => list[Math.floor(random() * list.length)];
    let today = '2026-06-01';
    let time = '09:00';
    const clock = () => `${today}T${time}`;

    const bodies = [
      { care_family: 'parasite_prevention', frequency: 'monthly', next_due_date: '2026-06-03', name: 'Flea' },
      { care_family: 'vaccination', frequency: 'yearly', next_due_date: '2026-06-05', planned_dates: ['2026-07-05'], name: 'DHPP' },
      { care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', schedule_times: ['08:00', '18:00'], name: 'Apoquel' },
      { care_family: 'medication', frequency: 'weekly', next_due_date: '2026-06-02', name: 'Injection' },
      { care_family: 'dental', frequency: 'daily', next_due_date: '2026-06-01', name: 'Chew' },
      { care_family: 'grooming', frequency: 'weekly', frequency_interval: 6, next_due_date: '2026-06-20', name: 'Groom' },
    ];
    const items = [];
    for (const body of bodies) {
      const res = await api.at(clock()).create(body);
      expect(res.statusCode).toBe(201);
      items.push(res.body.id);
    }

    const failures = [];
    for (let step = 0; step < STEPS; step += 1) {
      if (random() < 0.3) {
        today = addDaysIso(today, Math.floor(random() * 3));
        time = pick(['06:30', '08:30', '12:00', '15:00', '18:30', '22:00']);
      }
      const id = pick(items);
      const read = await api.at(clock()).get(id);
      const entry = read.body;
      const open = entry.open_occurrences || [];
      const occ = open.length ? pick(open) : null;
      const action = pick([
        'complete', 'complete', 'complete', 'skip', 'plan', 'reschedule', 'following',
        'postpone', 'pause', 'resume', 'undo', 'tick', 'stack', 'record',
      ]);
      let res = null;
      if (action === 'complete' && occ) {
        // No choice falls back to keep (D-CSM-026 v4); explicit choices are mixed in.
        res = await api.at(clock()).complete(id, occ.id, pick([
          {},
          {},
          { next_choice: pick(['keep', 'skip_next', 'shift_following']) },
          { earlier_choice: pick(['complete', 'skip', 'keep']) },
        ]));
      } else if (action === 'skip' && occ) {
        res = await api.at(clock()).skip(id, occ.id);
      } else if (action === 'plan') {
        res = await api.at(clock()).plan(id, { scheduled_date: addDaysIso(today, 1 + Math.floor(random() * 40)) });
      } else if ((action === 'reschedule' || action === 'following') && occ) {
        res = await api.at(clock()).reschedule(id, occ.id, {
          scheduled_date: addDaysIso(today, Math.floor(random() * 10)),
          scope: action === 'following' ? 'following' : 'this',
        });
      } else if (action === 'postpone') {
        res = await api.at(clock()).postpone(id, { until: addDaysIso(today, 1 + Math.floor(random() * 15)) });
      } else if (action === 'pause') {
        res = await api.at(clock()).postpone(id, { until: null });
      } else if (action === 'resume') {
        res = await api.at(clock()).resume(id, {});
      } else if (action === 'undo') {
        res = await api.at(clock()).undo(id);
      } else if (action === 'tick') {
        await runCareTick(harness.pool, { clock: { todayIso: today, nowTimeIso: time } });
      } else if (action === 'stack') {
        const stack = open.filter((o) => o.status === 'not_recorded' || o.status === 'overdue');
        if (stack.length) {
          const given = stack.filter(() => random() < 0.5).map((o) => o.id);
          const notGiven = stack.filter((o) => !given.includes(o.id)).map((o) => o.id);
          res = await api.at(clock()).resolveStack(id, { given, not_given: notGiven });
        }
      } else if (action === 'record') {
        const rows = await occurrenceRows(harness.pool, id);
        const closed = rows.find((r) => r.close_reason === 'not_recorded');
        if (closed) res = await api.at(clock()).record(id, closed.id);
      }
      if (res && res.statusCode >= 500) {
        failures.push(`step ${step} ${action} ${id}: ${res.statusCode} ${JSON.stringify(res.body)}`);
      }
      const violations = await invariantViolations(harness.pool, id);
      if (violations.length) {
        failures.push(`step ${step} ${action} at ${clock()} on ${entry.name}: ${violations.join(', ')}`);
      }
      if (failures.length > 5) break;
    }
    expect(failures).toEqual([]);
  }, 180000);
});
