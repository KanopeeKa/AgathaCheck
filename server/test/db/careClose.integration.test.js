/**
 * CARE-STATUS-R-015, R-016, R-018 — Close care command and date matrix.
 */
import { randomUUID } from 'crypto';

import jwt from 'jsonwebtoken';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  careApi,
  createOwner,
  occurrenceRows,
  openStrictHarness,
  removeOwner,
} from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

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
  care_family: 'parasite_prevention',
  frequency: 'monthly',
  next_due_date: due,
  name: 'Flea',
});

async function created(body, clock) {
  const res = await api.at(clock).create(body);
  expect(res.statusCode).toBe(201);
  return res.body;
}

async function createCarerApi() {
  const carerId = randomUUID();
  await harness.pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Carer', 'User')`,
    [carerId, `carer-${carerId}@example.com`],
  );
  await harness.pool.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role) VALUES ($1, $2, $3, 'carer')`,
    [randomUUID(), owner.petId, carerId],
  );
  const token = jwt.sign({ id: carerId, email: `carer-${carerId}@example.com` }, JWT_SECRET, {
    expiresIn: '1h',
  });
  return careApi(harness.app, { userId: carerId, petId: owner.petId, token });
}

describe('CARE-STATUS close care', () => {
  it('R-015 carer receives 403 owner_only on close', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const carerApi = await createCarerApi();
    const res = await carerApi.at('2026-06-01T09:00').close(entry.id);
    expect(res.statusCode).toBe(403);
    expect(res.body.code).toBe('owner_only');
  });

  it('R-018 started open becomes Not recorded and removes future open dates', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    expect(entry.open_occurrences).toHaveLength(1);

    const closed = await api.at('2026-06-06T09:00').close(entry.id);
    expect(closed.statusCode).toBe(200);
    expect(closed.body.status).toBe('closed');
    expect(closed.body.care_closed_reason).toBe('stopped_by_user');

    const rows = await occurrenceRows(harness.pool, entry.id);
    expect(rows.filter((r) => r.status === 'pending')).toHaveLength(0);
    expect(rows.some((r) => r.date === '2026-06-05' && r.status === 'not_recorded')).toBe(true);
  });

  it('R-019 paused care can be closed', async () => {
    const entry = await created(flea('2026-06-05'), '2026-06-01T09:00');
    const paused = await api.at('2026-06-01T09:00').postpone(entry.id, {
      paused_until: '2026-12-01',
    });
    expect(paused.statusCode).toBe(200);
    const closed = await api.at('2026-06-02T09:00').close(entry.id);
    expect(closed.statusCode).toBe(200);
    expect(closed.body.status).toBe('closed');
  });
});
