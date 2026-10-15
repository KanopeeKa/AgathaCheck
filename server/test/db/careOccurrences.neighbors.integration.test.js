/**
 * CARE-ITEM-R-020: chronological previous/next on GET occurrence.
 */
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi,
  createOwner,
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

const flea = (due) => ({
  care_family: 'parasite_prevention',
  frequency: 'monthly',
  next_due_date: due,
  name: 'Flea',
});

describe('occurrence neighbours on GET', () => {
  it('returns previous and next across completed and open rows', async () => {
    const create = await api
        .at('2026-06-05T09:00')
        .create({ ...flea('2026-06-05'), start_date: '2026-06-05' });
    expect(create.statusCode).toBe(201);
    const entry = create.body;
    const first = entry.open_occurrences[0];
    const done = await api
        .at('2026-06-10T09:00')
        .complete(entry.id, first.id, { completed_on: '2026-06-10' });
    expect(done.statusCode).toBe(200);
    const second = done.body.entry.open_occurrences[0];

    const mid = await api.at('2026-06-12T09:00').occurrence(entry.id, second.id);
    expect(mid.statusCode).toBe(200);
    expect(mid.body.previous_occurrence).toMatchObject({
      id: first.id,
      occurrence_status: 'done',
      completed_on: '2026-06-10',
    });
    expect(mid.body.next_occurrence).toBeNull();
  });

  it('does not leak neighbours from another entry', async () => {
    const a = await api.at('2026-06-05T09:00').create({
      ...flea('2026-06-05'),
      start_date: '2026-06-05',
      name: 'A',
    });
    const b = await api.at('2026-06-05T09:00').create({
      ...flea('2026-06-20'),
      start_date: '2026-06-20',
      name: 'B',
    });
    const occA = a.body.open_occurrences[0];
    const res = await api.at('2026-06-07T09:00').occurrence(b.body.id, b.body.open_occurrences[0].id);
    expect(res.statusCode).toBe(200);
    expect(res.body.previous_occurrence?.id).not.toBe(occA.id);
  });
});
