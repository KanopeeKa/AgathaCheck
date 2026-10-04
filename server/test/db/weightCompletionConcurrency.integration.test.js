import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import request from 'supertest';

import {
  careApi, createDbPool, createOwner, openHarness, removeOwner,
} from './helpers/careHarness.js';

let harness;
let owner;
let api;

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) {
    const probe = createDbPool();
    try {
      await probe.query(
        `SELECT 1 FROM information_schema.columns
         WHERE table_name = 'health_occurrences' AND column_name = 'origin'`,
      );
      throw new Error('Care DB integration tests require the migrated health_occurrences.origin column');
    } finally {
      await probe.end();
    }
  }
  owner = await createOwner(harness.pool, { timeZone: 'Europe/Paris' });
  api = careApi(harness.app, owner);
}, 30000);

afterAll(async () => {
  if (harness?.pool) {
    await harness.pool.query('DELETE FROM weight_entries WHERE pet_id = $1', [owner.petId]);
    await removeOwner(harness.pool, owner);
    await harness.pool.end();
  }
});

async function monthlyWeighIn(nextDueDate = '2026-06-01') {
  const res = await api.at(`${nextDueDate}T09:00`).create({
    name: `Monthly weigh-in ${nextDueDate}`,
    care_family: 'weight_monitoring',
    frequency: 'monthly',
    recurrence_anchor: 'from_due_date',
    next_due_date: nextDueDate,
  });
  expect(res.statusCode).toBe(201);
  return res.body;
}

function completeViaHttp(entry, occurrenceId, body) {
  return request(harness.app)
    .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occurrenceId}/complete-weight`)
    .set('Authorization', `Bearer ${owner.token}`)
    .set('X-Care-As-Of', `${body.date}T10:00`)
    .send(body);
}

describe('weight completion concurrency (real PG)', () => {
  it('creates one weight_entries row for concurrent identical completions', async () => {
    const entry = await monthlyWeighIn('2026-08-01');
    const occurrenceId = entry.open_occurrences[0].id;
    const body = {
      weight: 11.2,
      unit: 'kg',
      date: '2026-08-01',
      completed_on: '2026-08-01',
    };

    const [a, b] = await Promise.all([
      completeViaHttp(entry, occurrenceId, body),
      completeViaHttp(entry, occurrenceId, body),
    ]);

    const weights = await harness.pool.query(
      'SELECT COUNT(*)::int AS count FROM weight_entries WHERE health_occurrence_id = $1',
      [occurrenceId],
    );
    expect(weights.rows[0].count).toBe(1);
    expect([a.statusCode, b.statusCode].sort()).toEqual([200, 201]);
  });

  it('returns 409 when payload differs on replay', async () => {
    const entry = await monthlyWeighIn('2026-10-01');
    const occurrenceId = entry.open_occurrences[0].id;
    const first = await request(harness.app)
      .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occurrenceId}/complete-weight`)
      .set('Authorization', `Bearer ${owner.token}`)
      .set('X-Care-As-Of', '2026-10-01T10:00')
      .send({
        weight: 10.5,
        unit: 'kg',
        date: '2026-10-01',
        completed_on: '2026-10-01',
      });
    expect(first.statusCode).toBe(201);

    const conflict = await request(harness.app)
      .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occurrenceId}/complete-weight`)
      .set('Authorization', `Bearer ${owner.token}`)
      .set('X-Care-As-Of', '2026-10-01T10:00')
      .send({
        weight: 10.6,
        unit: 'kg',
        date: '2026-10-01',
        completed_on: '2026-10-01',
      });
    expect(conflict.statusCode).toBe(409);
  });
});
