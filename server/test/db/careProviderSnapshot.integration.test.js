/**
 * PEOPLE invariant I12 (parallel-programmes.md §6 CARE 3): the occurrence
 * records the provider of the contact attached to the care item, even when
 * the person completing it is a co-parent or carer whose own directory does
 * not contain that contact. The write is authorised by pet access.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import jwt from 'jsonwebtoken';

import { careApi, createOwner, openHarness, removeOwner } from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

let harness;
let owner;
let coParent;
let contactId;

beforeAll(async () => {
  harness = await openHarness();
  if (!harness.pool) return;
  owner = await createOwner(harness.pool);
  const directoryId = randomUUID();
  contactId = randomUUID();
  await harness.pool.query(
    'INSERT INTO people_directories (id, owner_user_id) VALUES ($1, $2)',
    [directoryId, owner.userId],
  );
  await harness.pool.query(
    `INSERT INTO people_contacts (id, directory_id, kind, name, phone)
     VALUES ($1, $2, 'organisation', 'Greenhill Veterinary Clinic', '+44 20 0000 0000')`,
    [contactId, directoryId],
  );
  const coParentId = randomUUID();
  await harness.pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Co', 'Parent')`,
    [coParentId, `co-${coParentId}@example.com`],
  );
  await harness.pool.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role) VALUES ($1, $2, $3, 'co_parent')`,
    [randomUUID(), owner.petId, coParentId],
  );
  coParent = {
    userId: coParentId,
    petId: owner.petId,
    token: jwt.sign({ id: coParentId, email: `co-${coParentId}@example.com` }, JWT_SECRET, { expiresIn: '1h' }),
  };
}, 30000);

afterAll(async () => {
  if (!harness?.pool) return;
  await harness.pool.query('DELETE FROM pet_access WHERE user_id = $1', [coParent.userId]);
  await removeOwner(harness.pool, owner);
  await harness.pool.query('DELETE FROM people_contacts WHERE id = $1', [contactId]);
  await harness.pool.query('DELETE FROM people_directories WHERE owner_user_id = $1', [owner.userId]);
  await harness.pool.query('DELETE FROM users WHERE id = $1', [coParent.userId]);
  await harness.pool.end();
});

describe('provider snapshot on completion (I12)', () => {
  it('a co-parent completing care keeps the item\'s provider', async () => {
    if (!harness.pool) return;
    const created = await careApi(harness.app, owner).at('2026-06-05T09:00').create({
      care_family: 'wellness_review',
      frequency: 'yearly',
      next_due_date: '2026-06-05',
      provider_contact_id: contactId,
    });
    expect(created.statusCode).toBe(201);
    const occ = created.body.open_occurrences[0];
    const done = await careApi(harness.app, coParent).at('2026-06-05T10:00').complete(created.body.id, occ.id, {});
    expect(done.statusCode).toBe(200);
    const row = await harness.pool.query(
      'SELECT provider_contact_id, provider_contact_snapshot FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(row.rows[0].provider_contact_id).toBe(contactId);
    expect(row.rows[0].provider_contact_snapshot).toMatchObject({
      contact_id: contactId,
      name: 'Greenhill Veterinary Clinic',
      kind: 'organisation',
    });
  });

  it('an override the completer cannot see falls back to the item\'s provider', async () => {
    if (!harness.pool) return;
    const created = await careApi(harness.app, owner).at('2026-06-05T09:00').create({
      care_family: 'wellness_review',
      frequency: 'yearly',
      next_due_date: '2026-06-06',
      provider_contact_id: contactId,
    });
    const occ = created.body.open_occurrences[0];
    const done = await careApi(harness.app, coParent).at('2026-06-06T10:00').complete(created.body.id, occ.id, {
      provider_contact_id: randomUUID(),
    });
    expect(done.statusCode).toBe(200);
    const row = await harness.pool.query(
      'SELECT provider_contact_id FROM health_occurrences WHERE id = $1',
      [occ.id],
    );
    expect(row.rows[0].provider_contact_id).toBe(contactId);
  });
});
