/**
 * W2 linked weigh-in integrity (§8.2 L-1 … L-12).
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import request from 'supertest';

import {
  careApi,
  createOwner,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

async function createWeighIn(due = '2026-06-01') {
  const res = await api.at(`${due}T09:00`).create({
    name: 'Monthly weigh-in',
    care_family: 'weight_monitoring',
    frequency: 'monthly',
    recurrence_anchor: 'from_due_date',
    next_due_date: due,
    start_date: due,
  });
  expect(res.statusCode).toBe(201);
  return res.body;
}

function completeWeight(entry, occId, clock, body) {
  return request(harness.app)
    .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occId}/complete-weight`)
    .set('Authorization', `Bearer ${owner.token}`)
    .set('X-Care-As-Of', clock)
    .send(body);
}

function putWeight(id, clock, body) {
  return request(harness.app)
    .put(`/api/weight-entries/${id}`)
    .set('Authorization', `Bearer ${owner.token}`)
    .set('X-Care-As-Of', clock)
    .send(body);
}

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool, { timeZone: 'UTC' });
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await harness.pool.query('DELETE FROM weight_entries WHERE pet_id = $1', [owner.petId]);
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

describe('W2 weigh-in integrity', () => {
  it('L-1 complete-weight → undo deletes weight and allows re-complete', async () => {
    const entry = await createWeighIn();
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-06-01T10:00', {
      weight: 10.2, unit: 'kg', date: '2026-06-01', completed_on: '2026-06-01',
    });
    expect(done.statusCode).toBe(201);
    const weightId = done.body.weight_entry.id;
    const undo = await api.at('2026-06-01T10:05').undo(entry.id, { undo_token: done.body.undo_token });
    expect(undo.statusCode).toBe(200);
    const weightRow = await harness.pool.query('SELECT id FROM weight_entries WHERE id = $1', [weightId]);
    expect(weightRow.rows).toHaveLength(0);
    const occRow = await harness.pool.query(
      'SELECT status FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(occRow.rows[0].status).toBe('pending');
    const pet = await harness.pool.query('SELECT weight FROM pets WHERE id = $1', [owner.petId]);
    expect(Number(pet.rows[0].weight)).toBeNaN() || pet.rows[0].weight == null;

    const again = await completeWeight(entry, occ.id, '2026-06-01T11:00', {
      weight: 11.1, unit: 'kg', date: '2026-06-01', completed_on: '2026-06-01',
    });
    expect(again.statusCode).toBe(201);
  });

  it('L-2 legacy completed ledger without observation unlinks weight on undo', async () => {
    const entry = await createWeighIn('2026-06-10');
    const occ = entry.open_occurrences[0];
    const weightId = randomUUID();
    await harness.pool.query(
      `INSERT INTO weight_entries
        (id, pet_id, user_id, weight, unit, date, notes, measurement_source, health_occurrence_id)
       VALUES ($1, $2, $3, 9.5, 'kg', '2026-06-10', '', 'guardian', $4)`,
      [weightId, owner.petId, owner.userId, occ.id],
    );
    await harness.pool.query(
      `UPDATE health_occurrences SET status = 'completed', completed_on = '2026-06-10'
       WHERE id = $1`,
      [occ.id],
    );
    const eventId = randomUUID();
    await harness.pool.query(
      `INSERT INTO care_schedule_events
        (id, health_entry_id, health_occurrence_id, event_type, payload, occurred_at)
       VALUES ($1, $2, $3, 'completed', $4::jsonb, NOW())`,
      [
        eventId,
        entry.id,
        occ.id,
        JSON.stringify({ closed: [{ id: occ.id, status: 'completed' }], created: [] }),
      ],
    );
    const undo = await api.at('2026-06-10T12:00').undo(entry.id, { undo_token: eventId });
    expect(undo.statusCode).toBe(200);
    const weight = await harness.pool.query(
      'SELECT health_occurrence_id FROM weight_entries WHERE id = $1',
      [weightId],
    );
    expect(weight.rows[0].health_occurrence_id).toBeNull();
    const occRow = await harness.pool.query('SELECT status FROM health_occurrences WHERE id = $1', [occ.id]);
    expect(occRow.rows[0].status).toBe('pending');
  });

  it('L-3 PUT linked weight date syncs completed_on and returns undo_token', async () => {
    const entry = await createWeighIn('2026-06-05');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-06-05T10:00', {
      weight: 12, unit: 'kg', date: '2026-06-05', completed_on: '2026-06-05',
    });
    expect(done.statusCode).toBe(201);
    const weightId = done.body.weight_entry.id;
    const updated = await putWeight(weightId, '2026-06-08T10:00', {
      weight: 12, unit: 'kg', date: '2026-06-08', measurement_source: 'guardian',
    });
    expect(updated.statusCode).toBe(200);
    expect(updated.body.undo_token).toBeTruthy();
    const occRow = await harness.pool.query(
      'SELECT completed_on, completion_timing FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(String(occRow.rows[0].completed_on).slice(0, 10)).toBe('2026-06-08');
    expect(occRow.rows[0].completion_timing).toBeTruthy();
    const events = await harness.pool.query(
      `SELECT event_type FROM care_schedule_events
       WHERE health_entry_id = $1 AND event_type = 'completion_date_changed' AND undone_at IS NULL`,
      [entry.id],
    );
    expect(events.rows.length).toBeGreaterThanOrEqual(1);
  });

  it('L-4 undo of L-3 date change restores both dates', async () => {
    const entry = await createWeighIn('2026-07-01');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-07-01T10:00', {
      weight: 13, unit: 'kg', date: '2026-07-01', completed_on: '2026-07-01',
    });
    const weightId = done.body.weight_entry.id;
    const updated = await putWeight(weightId, '2026-07-03T10:00', {
      weight: 13, unit: 'kg', date: '2026-07-03', measurement_source: 'guardian',
    });
    const undo = await api.at('2026-07-03T10:05').undo(entry.id, { undo_token: updated.body.undo_token });
    expect(undo.statusCode).toBe(200);
    const occRow = await harness.pool.query(
      'SELECT completed_on FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(String(occRow.rows[0].completed_on).slice(0, 10)).toBe('2026-07-01');
    const weight = await harness.pool.query('SELECT date FROM weight_entries WHERE id = $1', [weightId]);
    expect(String(weight.rows[0].date).slice(0, 10)).toBe('2026-07-01');
  });

  it('L-5 PUT linked weight rejects invalid dates', async () => {
    const entry = await createWeighIn('2026-08-01');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-08-01T10:00', {
      weight: 14, unit: 'kg', date: '2026-08-01', completed_on: '2026-08-01',
    });
    const weightId = done.body.weight_entry.id;
    const future = await putWeight(weightId, '2026-08-01T10:00', {
      weight: 14, unit: 'kg', date: '2026-08-02', measurement_source: 'guardian',
    });
    expect(future.statusCode).toBe(400);
    expect(future.body.code).toBe('completed_on_in_future');
    const beforeStart = await putWeight(weightId, '2026-08-01T10:00', {
      weight: 14, unit: 'kg', date: '2026-07-31', measurement_source: 'guardian',
    });
    expect(beforeStart.statusCode).toBe(400);
    expect(beforeStart.body.code).toBe('completed_on_before_start');
  });

  it('L-6 PATCH occurrence completed_on moves linked weight date', async () => {
    const entry = await createWeighIn('2026-09-01');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-09-01T10:00', {
      weight: 15, unit: 'kg', date: '2026-09-01', completed_on: '2026-09-01',
    });
    const weightId = done.body.weight_entry.id;
    const patched = await api.at('2026-09-04T10:00').patchOccurrence(entry.id, occ.id, {
      completed_on: '2026-09-04',
    });
    expect(patched.statusCode).toBe(200);
    const weight = await harness.pool.query('SELECT date FROM weight_entries WHERE id = $1', [weightId]);
    expect(String(weight.rows[0].date).slice(0, 10)).toBe('2026-09-04');
    const undo = await api.at('2026-09-04T10:05').undo(entry.id, { undo_token: patched.body.undo_token });
    expect(undo.statusCode).toBe(200);
    const weightAfter = await harness.pool.query('SELECT date FROM weight_entries WHERE id = $1', [weightId]);
    expect(String(weightAfter.rows[0].date).slice(0, 10)).toBe('2026-09-01');
  });

  it('L-7 PUT linked weight value only does not add a care ledger event', async () => {
    const entry = await createWeighIn('2026-10-01');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-10-01T10:00', {
      weight: 16, unit: 'kg', date: '2026-10-01', completed_on: '2026-10-01',
    });
    const weightId = done.body.weight_entry.id;
    const before = await harness.pool.query(
      'SELECT COUNT(*)::int AS n FROM care_schedule_events WHERE health_entry_id = $1',
      [entry.id],
    );
    const updated = await putWeight(weightId, '2026-10-01T10:00', {
      weight: 16.5, unit: 'kg', date: '2026-10-01', measurement_source: 'guardian',
    });
    expect(updated.statusCode).toBe(200);
    expect(updated.body.undo_token).toBeUndefined();
    const after = await harness.pool.query(
      'SELECT COUNT(*)::int AS n FROM care_schedule_events WHERE health_entry_id = $1',
      [entry.id],
    );
    expect(after.rows[0].n).toBe(before.rows[0].n);
  });

  it('L-8 skip weigh-in stores reason in ledger and occurrence detail', async () => {
    const entry = await createWeighIn('2026-11-01');
    const occ = entry.open_occurrences[0];
    const skipped = await api.at('2026-11-01T10:00').skip(entry.id, occ.id, {
      reason_code: 'could_not_weigh',
      notes: 'Too wiggly',
    });
    expect(skipped.statusCode).toBe(200);
    const ledger = await harness.pool.query(
      `SELECT reason_code, reason_note FROM care_schedule_events
       WHERE health_occurrence_id = $1 AND event_type = 'skipped'`,
      [occ.id],
    );
    expect(ledger.rows[0]).toMatchObject({ reason_code: 'could_not_weigh', reason_note: 'Too wiggly' });
    const detail = await api.at('2026-11-01T10:05').occurrence(entry.id, occ.id);
    expect(detail.body.skip_reason).toEqual({ code: 'could_not_weigh', note: 'Too wiggly' });
  });

  it('L-9 invalid skip reason on weigh-in is rejected', async () => {
    const entry = await createWeighIn('2026-11-15');
    const occ = entry.open_occurrences[0];
    const res = await api.at('2026-11-15T10:00').skip(entry.id, occ.id, {
      reason_code: 'refused',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.code).toBe('invalid_skip_reason');
    const row = await harness.pool.query('SELECT status FROM health_occurrences WHERE id = $1', [occ.id]);
    expect(row.rows[0].status).toBe('pending');
  });

  it('L-10 medication skip accepts any reason_code', async () => {
    const med = await api.at('2026-12-01T09:00').create({
      name: 'Pill',
      care_family: 'medication',
      frequency: 'daily',
      next_due_date: '2026-12-01',
    });
    expect(med.statusCode).toBe(201);
    const occ = med.body.open_occurrences[0];
    const res = await api.at('2026-12-01T10:00').skip(med.body.id, occ.id, {
      reason_code: 'refused',
    });
    expect(res.statusCode).toBe(200);
  });

  it('L-11 occurrence detail returns full linked_weight shape', async () => {
    const entry = await createWeighIn('2026-05-20');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-05-20T10:00', {
      weight: 12.4, unit: 'kg', date: '2026-05-20', completed_on: '2026-05-20',
      measurement_source: 'clinic',
    });
    const weightId = done.body.weight_entry.id;
    const detail = await api.at('2026-05-20T10:05').occurrence(entry.id, occ.id);
    expect(detail.body.linked_weight).toMatchObject({
      id: weightId,
      value: 12.4,
      unit: 'kg',
      date: '2026-05-20',
      measurement_source: 'clinic',
    });
  });

  it('L-12 DELETE linked weight returns reopened_occurrence', async () => {
    const entry = await createWeighIn('2026-04-01');
    const occ = entry.open_occurrences[0];
    const done = await completeWeight(entry, occ.id, '2026-04-01T10:00', {
      weight: 8, unit: 'kg', date: '2026-04-01', completed_on: '2026-04-01',
    });
    const weightId = done.body.weight_entry.id;
    const del = await request(harness.app)
      .delete(`/api/weight-entries/${weightId}`)
      .set('Authorization', `Bearer ${owner.token}`);
    expect(del.statusCode).toBe(200);
    expect(del.body.reopened_occurrence).toEqual({
      entry_id: entry.id,
      occurrence_id: occ.id,
    });

    const standalone = await request(harness.app)
      .post('/api/weight-entries')
      .set('Authorization', `Bearer ${owner.token}`)
      .send({ pet_id: owner.petId, weight: 8.1, date: '2026-04-02', measurement_source: 'guardian' });
    const delStandalone = await request(harness.app)
      .delete(`/api/weight-entries/${standalone.body.id}`)
      .set('Authorization', `Bearer ${owner.token}`);
    expect(delStandalone.body.reopened_occurrence).toBeNull();
  });
});
