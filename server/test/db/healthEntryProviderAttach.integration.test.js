/**
 * B12 — care item writes reject provider contacts the caller cannot attach.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { careApi, createOwner, openStrictHarness, removeOwner } from './helpers/careHarness.js';

let harness;
let owner;
let stranger;
let strangerContactId;

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool);
  stranger = await createOwner(harness.pool);

  const directoryId = randomUUID();
  strangerContactId = randomUUID();
  await harness.pool.query(
    'INSERT INTO people_directories (id, owner_user_id) VALUES ($1, $2)',
    [directoryId, stranger.userId],
  );
  await harness.pool.query(
    `INSERT INTO people_contacts (id, directory_id, kind, name)
     VALUES ($1, $2, 'person', 'Stranger Walker')`,
    [strangerContactId, directoryId],
  );
}, 30000);

afterAll(async () => {
  if (!harness?.pool) return;
  await harness.pool.query('DELETE FROM people_contacts WHERE id = $1', [strangerContactId]);
  await harness.pool.query('DELETE FROM people_directories WHERE owner_user_id = $1', [stranger.userId]);
  await removeOwner(harness.pool, stranger);
  await removeOwner(harness.pool, owner);
  await harness.pool.end();
});

describe('health entry provider_contact_id (B12)', () => {
  it('rejects a provider from another user directory on create', async () => {
    const created = await careApi(harness.app, owner).at('2026-06-05T09:00').create({
      care_family: 'wellness_review',
      frequency: 'yearly',
      next_due_date: '2026-06-05',
      provider_contact_id: strangerContactId,
    });
    expect(created.statusCode).toBe(400);
    expect(created.body.code).toBe('validation_failed');
  });
});
