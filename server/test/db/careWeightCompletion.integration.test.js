/**
 * Weigh-in completion through `complete-weight` when done late with a waiting
 * date (D-CSM-026 v4): no choice keeps the next date and saves the weight.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import request from 'supertest';

import {
  careApi, createDbPool, createOwner, invariantViolations, occurrenceRows, openHarness, removeOwner,
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

async function monthlyWeighIn() {
  const res = await api.at('2026-06-01T09:00').create({
    name: 'Monthly weigh-in',
    care_family: 'weight_monitoring',
    frequency: 'monthly',
    recurrence_anchor: 'from_due_date',
    next_due_date: '2026-06-01',
  });
  expect(res.statusCode).toBe(201);
  return res.body;
}

function completeWeight(entry, occurrenceId, clock, body) {
  return request(harness.app)
    .post(`/api/pets/${owner.petId}/care-rhythms/${entry.id}/occurrences/${occurrenceId}/complete-weight`)
    .set('Authorization', `Bearer ${owner.token}`)
    .set('X-Care-As-Of', clock)
    .send(body);
}

describe('weigh-in done late (D-CSM-026 v4)', () => {
  it('saves the weight and keeps the next date when no choice is sent', async () => {
    const entry = await monthlyWeighIn();
    const first = entry.open_occurrences[0];
    expect(entry.open_occurrences.map((o) => o.scheduled_date)).toEqual(['2026-06-01', '2026-07-01']);

    const res = await completeWeight(entry, first.id, '2026-06-20T10:00', {
      weight: 12.4, unit: 'kg', date: '2026-06-20', completed_on: '2026-06-20',
    });
    expect(res.statusCode).toBe(201);
    expect(res.body.next_choice_applied).toBe('keep');
    expect(res.body.weight_entry).toMatchObject({ weight: 12.4, unit: 'kg' });

    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.find((r) => r.id === first.id).status).toBe('completed');
    expect(rows.filter((r) => r.status === 'pending').map((r) => r.date)).toEqual(['2026-07-01']);
    const weights = await harness.pool.query(
      'SELECT weight FROM weight_entries WHERE health_occurrence_id = $1',
      [first.id],
    );
    expect(weights.rows).toHaveLength(1);
    expect(await invariantViolations(harness.pool, entry.id)).toEqual([]);
  });

  it('applies an explicit choice', async () => {
    const entry = await monthlyWeighIn();
    const res = await completeWeight(entry, entry.open_occurrences[0].id, '2026-06-20T10:00', {
      weight: 12.6, unit: 'kg', date: '2026-06-20', completed_on: '2026-06-20', next_choice: 'skip_next',
    });
    expect(res.statusCode).toBe(201);
    expect(res.body.next_choice_applied).toBe('skip_next');
    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => r.status === 'pending').map((r) => r.date)).toEqual(['2026-08-01']);
  });
});
