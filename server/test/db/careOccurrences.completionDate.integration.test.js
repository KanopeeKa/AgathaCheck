/**
 * C0 (§18.7): one occurrence read, changing when care was done (D-CSM-034,
 * OS-1 … OS-3b) and history from occurrences (D-CSM-035).
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import request from 'supertest';

import { assertMatchesSchema } from '../../lib/openapi/assertDto.js';
import { loadPetCareCriticalSpec, responseSchema } from '../../lib/openapi/petCareCriticalSpec.js';
import {
  careApi,
  createOwner,
  invariantViolations,
  occurrenceRows,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

const spec = loadPetCareCriticalSpec();
const OCC_PATH = '/health-entries/{id}/occurrences/{occId}';
let harness;
let owner;
let stranger;
let api;

function assertResponse(method, status, body) {
  const schema = responseSchema(spec, OCC_PATH, method, status);
  if (!schema) throw new Error(`No schema for ${method} ${OCC_PATH} ${status}`);
  assertMatchesSchema(spec, schema, body);
}

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
  stranger = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await harness.pool.query('DELETE FROM weight_entries WHERE pet_id = $1', [owner.petId]);
    await removeOwner(harness.pool, owner);
    await removeOwner(harness.pool, stranger);
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

/** Flea treatment due 5 Jun, done on 10 Jun: next computed date 10 Jul. */
async function fleaDoneLate() {
  const entry = await created({ ...flea('2026-06-05'), start_date: '2026-06-05' }, '2026-06-05T09:00');
  const first = entry.open_occurrences[0];
  const done = await api.at('2026-06-10T09:00').complete(entry.id, first.id, { completed_on: '2026-06-10' });
  expect(done.statusCode).toBe(200);
  expect(done.body.next_due_date).toBe('2026-07-10');
  return { entry, first, next: done.body.entry.open_occurrences[0] };
}

describe('GET one occurrence (§18.7.1)', () => {
  it('returns an open occurrence with its care item summary', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const occ = entry.open_occurrences[0];
    const res = await api.at('2026-06-07T09:00').occurrence(entry.id, occ.id);
    expect(res.statusCode).toBe(200);
    assertResponse('get', 200, res.body);
    expect(res.body.occurrence).toMatchObject({
      id: occ.id, scheduled_date: '2026-06-05', status: 'pending', occurrence_status: 'overdue',
    });
    expect(res.body.entry).toMatchObject({
      id: entry.id,
      pet_id: owner.petId,
      name: 'Flea',
      care_family: 'parasite_prevention',
      recurrence_anchor: 'from_completion',
      status: 'active',
      as_of: { date: '2026-06-07', time: '09:00', timezone: 'Europe/Paris' },
    });
    expect(res.body.last_action).toBeNull();
    expect(res.body.linked_weight).toBeUndefined();
  });

  it('returns a completed occurrence with the last action', async () => {
    const { entry, first } = await fleaDoneLate();
    const res = await api.at('2026-06-10T09:05').occurrence(entry.id, first.id);
    expect(res.statusCode).toBe(200);
    assertResponse('get', 200, res.body);
    expect(res.body.occurrence).toMatchObject({
      status: 'completed', occurrence_status: 'done', completed_on: '2026-06-10',
    });
    expect(res.body.last_action).toEqual({ type: 'completed', occurrence_id: first.id });
    const item = await api.at('2026-06-10T09:05').get(entry.id);
    expect(item.body.last_done).toEqual({ occurrence_id: first.id, completed_on: '2026-06-10', time: expect.stringMatching(/^\d\d:\d\d$/) });
  });

  it('carries the weight saved with a weigh-in', async () => {
    const entry = await created({
      name: 'Monthly weigh-in', care_family: 'weight_monitoring', frequency: 'monthly',
      recurrence_anchor: 'from_due_date', next_due_date: '2026-06-01',
    }, '2026-06-01T09:00');
    const occ = entry.open_occurrences[0];
    const saved = await request(harness.app)
      .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occ.id}/complete-weight`)
      .set('Authorization', `Bearer ${owner.token}`)
      .set('X-Care-As-Of', '2026-06-01T10:00')
      .send({ weight: 12.4, unit: 'kg', date: '2026-06-01', completed_on: '2026-06-01' });
    expect(saved.statusCode).toBe(201);
    const res = await api.at('2026-06-01T10:05').occurrence(entry.id, occ.id);
    expect(res.statusCode).toBe(200);
    assertResponse('get', 200, res.body);
    expect(res.body.linked_weight).toEqual({ value: 12.4, unit: 'kg' });
  });

  it('answers 404 for an unknown occurrence, one on another item, or another person\'s item', async () => {
    const a = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const b = await created(flea('2026-06-05'), '2026-06-05T09:00');
    const unknown = await api.at('2026-06-05T09:00').occurrence(a.id, randomUUID());
    expect(unknown.statusCode).toBe(404);
    assertResponse('get', 404, unknown.body);
    const elsewhere = await api.at('2026-06-05T09:00').occurrence(a.id, b.open_occurrences[0].id);
    expect(elsewhere.statusCode).toBe(404);
    const foreign = await careApi(harness.app, stranger).occurrence(a.id, a.open_occurrences[0].id);
    expect(foreign.statusCode).toBe(404);
  });
});

describe('changing when care was done (D-CSM-034)', () => {
  it('OS-1 Fixed schedule: only that occurrence changes', async () => {
    const entry = await created({
      care_family: 'medication', frequency: 'daily', next_due_date: '2026-06-01', name: 'Pill',
    }, '2026-06-01T07:00');
    expect(entry.recurrence_anchor).toBe('from_due_date');
    const first = entry.open_occurrences[0];
    await api.at('2026-06-02T09:00').complete(entry.id, first.id, { completed_on: '2026-06-02' });
    const before = (await occurrenceRows(harness.pool, entry.id)).filter((r) => r.id !== first.id);

    const res = await api.at('2026-06-02T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-01' });
    expect(res.statusCode).toBe(200);
    assertResponse('patch', 200, res.body);
    expect(res.body).toMatchObject({
      id: first.id, completed_on: '2026-06-01', moved_next_id: null, next_unchanged: false,
    });
    expect(res.body.undo_token).toBeTruthy();
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === first.id).completed_on).toBe('2026-06-01');
    expect(rows.filter((r) => r.id !== first.id)).toEqual(before);
    const timing = await harness.pool.query('SELECT completion_timing FROM health_occurrences WHERE id = $1', [first.id]);
    expect(timing.rows[0].completion_timing).toBe('on_time');
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('OS-2 After it\'s done: the computed next date its completion created moves with it', async () => {
    const { entry, first, next } = await fleaDoneLate();
    const res = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-08' });
    expect(res.statusCode).toBe(200);
    expect(res.body.moved_next_id).toBe(next.id);
    expect(res.body.next_unchanged).toBe(false);
    expect(res.body.next_due_date).toBe('2026-07-08');
    expect(res.body.entry.open_occurrences.map((o) => `${o.id}:${o.scheduled_date}:${o.origin}`))
      .toEqual([`${next.id}:2026-07-08:computed`]);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('OS-3 a next date a person moved stays, and the answer says so', async () => {
    const { entry, first, next } = await fleaDoneLate();
    const moved = await api.at('2026-06-10T09:01').reschedule(entry.id, next.id, { scheduled_date: '2026-07-20' });
    expect(moved.statusCode).toBe(200);
    const res = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-08' });
    expect(res.statusCode).toBe(200);
    expect(res.body.moved_next_id).toBeNull();
    expect(res.body.next_unchanged).toBe(true);
    expect(res.body.next_due_date).toBe('2026-07-20');
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('OS-3b undo right after reverses the date change only', async () => {
    const { entry, first, next } = await fleaDoneLate();
    const changed = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-08' });
    const undone = await api.at('2026-06-10T09:06').undo(entry.id, { undo_token: changed.body.undo_token });
    expect(undone.statusCode).toBe(200);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === first.id)).toMatchObject({ status: 'completed', completed_on: '2026-06-10' });
    expect(rows.find((r) => r.id === next.id)).toMatchObject({ status: 'pending', date: '2026-07-10', origin: 'computed' });
    const last = await api.at('2026-06-10T09:07').occurrence(entry.id, first.id);
    expect(last.body.last_action).toEqual({ type: 'completed', occurrence_id: first.id });
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('an earlier completion changes its date only', async () => {
    const { entry, first, next } = await fleaDoneLate();
    await api.at('2026-07-10T09:00').complete(entry.id, next.id, { completed_on: '2026-07-10' });
    const res = await api.at('2026-07-10T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-09' });
    expect(res.statusCode).toBe(200);
    expect(res.body.moved_next_id).toBeNull();
    expect(res.body.next_unchanged).toBe(false);
    expect(res.body.next_due_date).toBe('2026-08-10');
  });

  it('refuses invalid changes and saves nothing', async () => {
    const { entry, first, next } = await fleaDoneLate();
    const cases = [
      [{ completed_on: '2026-06-11' }, 400, 'completed_on_in_future'],
      [{ completed_on: '2026-06-01' }, 400, 'completed_on_before_start'],
      [{ completed_on: 'soon' }, 400, 'invalid_completed_on'],
      [{ completed_on: null }, 400, 'invalid_completed_on'],
      [{ completed_on: '2026-06-09', notes: 'x' }, 400, 'completed_on_with_other_fields'],
    ];
    for (const [body, status, code] of cases) {
      const res = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, body);
      expect(res.statusCode).toBe(status);
      expect(res.body.code).toBe(code);
      assertResponse('patch', 400, res.body);
    }
    const open = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, next.id, { completed_on: '2026-06-09' });
    expect(open.statusCode).toBe(409);
    expect(open.body.code).toBe('occurrence_not_completed');
    assertResponse('patch', 409, open.body);
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === first.id).completed_on).toBe('2026-06-10');
  });

  it('the same date is a no-op with no undo entry', async () => {
    const { entry, first } = await fleaDoneLate();
    const res = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, { completed_on: '2026-06-10' });
    expect(res.statusCode).toBe(200);
    expect(res.body.undo_token).toBeNull();
  });

  it('notes still change on their own', async () => {
    const { entry, first } = await fleaDoneLate();
    const res = await api.at('2026-06-10T09:05').patchOccurrence(entry.id, first.id, { notes: 'Given with food' });
    expect(res.statusCode).toBe(200);
    expect(res.body).toMatchObject({ id: first.id, notes: 'Given with food', completed_on: '2026-06-10' });
  });
});

describe('history from occurrences (D-CSM-035)', () => {
  it('lists completed and skipped dates with the history fields', async () => {
    const { entry, first, next } = await fleaDoneLate();
    await api.at('2026-07-11T09:00').skip(entry.id, next.id);
    const res = await api.at('2026-07-11T09:05').history(entry.id);
    expect(res.statusCode).toBe(200);
    expect(res.body.map((h) => `${h.status}:${h.due_date}:${h.completed_on}`))
      .toEqual(['skipped:2026-07-10:null', 'completed:2026-06-05:2026-06-10']);
    expect(res.body[1]).toMatchObject({
      id: first.id, health_entry_id: entry.id, entry_id: entry.id, marked_by_user_id: owner.userId,
    });
    expect(res.body[1].changed_at).toBeTruthy();
    const foreign = await careApi(harness.app, stranger).history(entry.id);
    expect(foreign.statusCode).toBe(404);
  });
});
