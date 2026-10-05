/**
 * W3 fulfilment (§8.3 F-11 … F-24).
 */
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

async function createWeighIn(name, due = '2026-10-10', extra = {}) {
  const res = await api.at(`${due}T09:00`).create({
    name,
    care_family: 'weight_monitoring',
    frequency: 'monthly',
    recurrence_anchor: 'from_due_date',
    next_due_date: due,
    start_date: due,
    ...extra,
  });
  expect(res.statusCode).toBe(201);
  return res.body;
}

function weightApi(token) {
  const withAuth = (req, clock) => {
    let r = req.set('Authorization', `Bearer ${token}`);
    if (clock) r = r.set('X-Care-As-Of', clock);
    return r;
  };
  return {
    candidates(petId, date, clock) {
      const req = request(harness.app).get('/api/weight-entries/fulfilment-candidates')
        .query({ pet_id: petId, ...(date ? { date } : {}) });
      return withAuth(req, clock);
    },
    overview(petId, clock) {
      return withAuth(
        request(harness.app).get('/api/weight-entries/overview').query({ pet_id: petId }),
        clock,
      );
    },
    post(body, clock) {
      return withAuth(request(harness.app).post('/api/weight-entries').send(body), clock);
    },
    fulfil(weightId, occurrenceId, clock) {
      return withAuth(
        request(harness.app).post(`/api/weight-entries/${weightId}/fulfil`).send({ occurrence_id: occurrenceId }),
        clock,
      );
    },
    list(petId, clock) {
      return withAuth(
        request(harness.app).get('/api/weight-entries').query({ pet_id: petId }),
        clock,
      );
    },
  };
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

describe('W3 weight fulfilment endpoints', () => {
  const w = () => weightApi(owner.token);

  it('F-11 candidates: one routine due sets default_occurrence_id', async () => {
    const entry = await createWeighIn('Monthly', '2026-10-10');
    const occ = entry.open_occurrences[0];
    const res = await w().candidates(owner.petId, '2026-10-12', '2026-10-12T10:00');
    expect(res.statusCode).toBe(200);
    expect(res.body.candidates).toHaveLength(1);
    expect(res.body.default_occurrence_id).toBe(occ.id);
  });

  it('F-12 candidates: two routines eligible, no default', async () => {
    await createWeighIn('Routine A', '2026-10-08');
    await createWeighIn('Routine B', '2026-10-09');
    const res = await w().candidates(owner.petId, '2026-10-12', '2026-10-12T10:00');
    expect(res.statusCode).toBe(200);
    expect(res.body.candidates.length).toBeGreaterThanOrEqual(2);
    expect(res.body.default_occurrence_id).toBeNull();
  });

  it('F-13 candidates: stacked pending returns only the earlier occurrence', async () => {
    const entry = await createWeighIn('Stacked', '2026-10-01');
    expect(entry.open_occurrences.length).toBeGreaterThanOrEqual(2);
    const res = await w().candidates(owner.petId, '2026-10-12', '2026-10-12T10:00');
    const forEntry = res.body.candidates.filter((c) => c.entry_id === entry.id);
    expect(forEntry).toHaveLength(1);
    expect(forEntry[0].occurrence_id).toBe(entry.open_occurrences[0].id);
  });

  it('F-14 candidates for another user pet returns 403', async () => {
    const stranger = await createOwner(harness.pool);
    const res = await weightApi(stranger.token)
      .candidates(owner.petId, '2026-10-12', '2026-10-12T10:00');
    expect(res.statusCode).toBe(403);
    await removeOwner(harness.pool, stranger);
  });

  it('F-15 POST with eligible fulfils_occurrence_id completes weigh-in', async () => {
    const entry = await createWeighIn('Fulfil create', '2026-11-01');
    const occ = entry.open_occurrences[0];
    const res = await w().post({
      pet_id: owner.petId,
      weight: 10.5,
      unit: 'kg',
      date: '2026-11-05',
      fulfils_occurrence_id: occ.id,
    }, '2026-11-05T10:00');
    expect(res.statusCode).toBe(201);
    expect(res.body.health_occurrence_id).toBe(occ.id);
    expect(res.body.fulfilment?.undo_token).toBeTruthy();
    const events = await harness.pool.query(
      `SELECT payload FROM care_schedule_events
       WHERE health_entry_id = $1 AND event_type = 'completed' AND undone_at IS NULL
       ORDER BY created_at DESC LIMIT 1`,
      [entry.id],
    );
    expect(events.rows[0].payload.observation).toMatchObject({
      kind: 'numeric_weight',
      created: true,
    });
    const occRow = await harness.pool.query(
      'SELECT status, completed_on FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(occRow.rows[0].status).toBe('completed');
  });

  it('F-16 POST with ineligible occurrence returns 409 fulfilment_not_eligible', async () => {
    const entry = await createWeighIn('Ineligible', '2026-12-01');
    const occ = entry.open_occurrences[0];
    const res = await w().post({
      pet_id: owner.petId,
      weight: 9.9,
      date: '2026-09-01',
      fulfils_occurrence_id: occ.id,
    }, '2026-12-01T10:00');
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('fulfilment_not_eligible');
    const count = await harness.pool.query(
      'SELECT COUNT(*)::int AS c FROM weight_entries WHERE pet_id = $1 AND date = $2',
      [owner.petId, '2026-09-01'],
    );
    expect(count.rows[0].c).toBe(0);
  });

  it('F-17 POST fulfil without care manage on entry returns 403', async () => {
    const victim = await createOwner(harness.pool);
    const victimEntry = await careApi(harness.app, victim).at('2026-10-10T09:00').create({
      name: 'Victim routine',
      care_family: 'weight_monitoring',
      frequency: 'monthly',
      next_due_date: '2026-10-10',
    });
    const victimOcc = victimEntry.body.open_occurrences[0].id;
    const attacker = await createOwner(harness.pool);
    const res = await weightApi(attacker.token).post({
      pet_id: attacker.petId,
      weight: 8,
      date: '2026-10-12',
      fulfils_occurrence_id: victimOcc,
    }, '2026-10-12T10:00');
    expect(res.statusCode).toBe(403);
    await removeOwner(harness.pool, victim);
    await removeOwner(harness.pool, attacker);
  });

  it('F-18 POST /:id/fulfil links standalone weight; undo keeps weight', async () => {
    const entry = await createWeighIn('Fulfil existing', '2027-01-10');
    const occ = entry.open_occurrences[0];
    const created = await w().post({
      pet_id: owner.petId,
      weight: 11,
      date: '2027-01-12',
    }, '2027-01-12T10:00');
    expect(created.statusCode).toBe(201);
    const weightId = created.body.id;
    const fulfilled = await w().fulfil(weightId, occ.id, '2027-01-12T11:00');
    expect(fulfilled.statusCode).toBe(200);
    expect(fulfilled.body.fulfilment?.undo_token).toBeTruthy();
    const undo = await api.at('2027-01-12T12:00').undo(entry.id, {
      undo_token: fulfilled.body.fulfilment.undo_token,
    });
    expect(undo.statusCode).toBe(200);
    const weight = await harness.pool.query(
      'SELECT health_occurrence_id FROM weight_entries WHERE id = $1',
      [weightId],
    );
    expect(weight.rows[0].health_occurrence_id).toBeNull();
    const occRow = await harness.pool.query('SELECT status FROM health_occurrences WHERE id = $1', [occ.id]);
    expect(occRow.rows[0].status).toBe('pending');
  });

  it('F-19 POST /:id/fulfil on linked weight returns already_linked', async () => {
    const entry = await createWeighIn('Already linked', '2027-02-10');
    const occ = entry.open_occurrences[0];
    const created = await w().post({
      pet_id: owner.petId,
      weight: 12,
      date: '2027-02-11',
      fulfils_occurrence_id: occ.id,
    }, '2027-02-11T10:00');
    const res = await w().fulfil(created.body.id, occ.id, '2027-02-11T11:00');
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('already_linked');
  });

  it('F-20 concurrent fulfil of same occurrence yields one success', async () => {
    const entry = await createWeighIn('Concurrent', '2027-03-10');
    const occ = entry.open_occurrences[0];
    const body = {
      pet_id: owner.petId,
      weight: 13.1,
      date: '2027-03-12',
      fulfils_occurrence_id: occ.id,
    };
    const clock = '2027-03-12T10:00';
    const [a, b] = await Promise.all([
      w().post(body, clock),
      w().post({ ...body, weight: 13.2 }, clock),
    ]);
    const statuses = [a.statusCode, b.statusCode].sort();
    expect(statuses).toEqual([201, 409]);
    const linked = await harness.pool.query(
      'SELECT COUNT(*)::int AS c FROM weight_entries WHERE health_occurrence_id = $1',
      [occ.id],
    );
    expect(linked.rows[0].c).toBe(1);
  });

  it('F-21 GET list includes fulfils for linked rows', async () => {
    const entry = await createWeighIn('List fulfils', '2027-04-10');
    const occ = entry.open_occurrences[0];
    await w().post({
      pet_id: owner.petId,
      weight: 14,
      date: '2027-04-11',
      fulfils_occurrence_id: occ.id,
    }, '2027-04-11T10:00');
    const list = await w().list(owner.petId, '2027-04-12T10:00');
    expect(list.statusCode).toBe(200);
    const linked = list.body.find((r) => r.fulfils?.occurrence_id === occ.id);
    expect(linked?.fulfils?.entry_name).toBe('List fulfils');
    expect(linked?.fulfils?.scheduled_date).toBeTruthy();
  });

  it('F-22 GET overview shape; closed absent, paused present', async () => {
    const active = await createWeighIn('Active overview', '2027-05-10');
    const paused = await createWeighIn('Paused overview', '2027-05-11');
    const pauseRes = await api.at('2027-05-01T10:00').postpone(paused.id, {});
    expect(pauseRes.statusCode).toBe(200);
    const closed = await createWeighIn('Closed overview', '2027-05-12');
    await api.at('2027-05-01T10:00').close(closed.id);
    const res = await w().overview(owner.petId, '2027-05-15T10:00');
    expect(res.statusCode).toBe(200);
    expect(res.body.pet_id).toBe(owner.petId);
    expect(res.body.as_of.date).toBe('2027-05-15');
    const ids = res.body.routines.map((r) => r.entry_id);
    expect(ids).toContain(active.id);
    expect(ids).toContain(paused.id);
    expect(ids).not.toContain(closed.id);
    const pausedRow = res.body.routines.find((r) => r.entry_id === paused.id);
    expect(pausedRow.status).toBe('paused');
  });

  it('F-23 fulfil on create links weight and establishes on 4th weekly weigh-in', async () => {
    const entry = await createWeighIn('Establishment', '2027-06-01', {
      frequency: 'weekly',
      frequency_interval: 1,
    });
    const fulfilDates = ['2027-06-01', '2027-06-08', '2027-06-15', '2027-06-22'];
    for (let i = 0; i < fulfilDates.length; i++) {
      const date = fulfilDates[i];
      const detail = await api.at(`${date}T09:00`).get(entry.id);
      expect(detail.statusCode).toBe(200);
      const occ = detail.body.open_occurrences[0];
      expect(occ?.id).toBeTruthy();
      const res = await w().post({
        pet_id: owner.petId,
        weight: 14 + i * 0.1,
        date,
        fulfils_occurrence_id: occ.id,
      }, `${date}T10:00`);
      expect(res.statusCode).toBe(201);
    }
    const est = await harness.pool.query(
      'SELECT id FROM care_establishments WHERE health_entry_id = $1',
      [entry.id],
    );
    expect(est.rows).toHaveLength(1);
  });

  it('F-24 GET history includes linked_weight after completed weigh-in', async () => {
    const entry = await createWeighIn('History weight', '2027-07-10');
    const occ = entry.open_occurrences[0];
    await w().post({
      pet_id: owner.petId,
      weight: 16.2,
      date: '2027-07-11',
      fulfils_occurrence_id: occ.id,
    }, '2027-07-11T10:00');
    const history = await api.at('2027-07-12T10:00').history(entry.id);
    expect(history.statusCode).toBe(200);
    const row = history.body.find((r) => r.id === occ.id);
    expect(row.linked_weight).toMatchObject({
      value: 16.2,
      unit: 'kg',
      date: '2027-07-11',
    });
  });
});
