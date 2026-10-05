/**
 * B3 / B10 — usage-aware contact delete and vet-linked cleanup.
 */
import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import jwt from 'jsonwebtoken';
import request from 'supertest';

import { createOwner, openStrictHarness, removeOwner } from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

let harness;
let owner;

async function ensurePersonalDirectory(pool, userId) {
  const existing = await pool.query(
    'SELECT id FROM people_directories WHERE owner_user_id = $1',
    [userId],
  );
  if (existing.rows[0]) return existing.rows[0].id;
  const directoryId = randomUUID();
  await pool.query(
    'INSERT INTO people_directories (id, owner_user_id) VALUES ($1, $2)',
    [directoryId, userId],
  );
  return directoryId;
}

async function insertContact(pool, userId, fields = {}) {
  const directoryId = await ensurePersonalDirectory(pool, userId);
  const contactId = fields.id || randomUUID();
  await pool.query(
    `INSERT INTO people_contacts (id, directory_id, kind, name, legacy_vet_id)
     VALUES ($1, $2, $3, $4, $5)`,
    [
      contactId,
      directoryId,
      fields.kind || 'organisation',
      fields.name || 'Test Vet',
      fields.legacy_vet_id || null,
    ],
  );
  if (fields.role) {
    await pool.query(
      'INSERT INTO people_contact_roles (contact_id, role) VALUES ($1, $2)',
      [contactId, fields.role],
    );
  }
  return contactId;
}

function peopleApi(app, token) {
  return {
    deleteContact(id) {
      return request(app)
        .delete(`/api/people/contacts/${id}`)
        .set('Authorization', `Bearer ${token}`);
    },
  };
}

beforeAll(async () => {
  harness = await openStrictHarness();
  owner = await createOwner(harness.pool);
}, 30000);

afterAll(async () => {
  if (!harness?.pool) return;
  await removeOwner(harness.pool, owner);
  await harness.pool.query('DELETE FROM people_directories WHERE owner_user_id = $1', [owner.userId]);
  await harness.pool.end();
});

describe('DELETE /api/people/contacts (usage-aware)', () => {
  it('B3: deletes an unused vet-linked contact and removes the vets row', async () => {
    const vetId = randomUUID();
    await harness.pool.query(
      `INSERT INTO vets (id, user_id, name, clinic, phone, email, website, address, notes)
       VALUES ($1, $2, 'Clinic', 'Test', null, null, '', '', '')`,
      [vetId, owner.userId],
    );
    const contactId = await insertContact(harness.pool, owner.userId, {
      name: 'Unused Vet',
      legacy_vet_id: vetId,
      role: 'vet',
    });

    const res = await peopleApi(harness.app, owner.token).deleteContact(contactId);
    expect(res.statusCode).toBe(200);

    const vetRow = await harness.pool.query('SELECT id FROM vets WHERE id = $1', [vetId]);
    expect(vetRow.rows).toHaveLength(0);
    const contactRow = await harness.pool.query(
      'SELECT id FROM people_contacts WHERE id = $1',
      [contactId],
    );
    expect(contactRow.rows).toHaveLength(0);
  });

  it('B10: returns 409 contact_in_use when contact is a care-item provider', async () => {
    const contactId = await insertContact(harness.pool, owner.userId, { name: 'Provider Clinic' });
    const entryId = randomUUID();
    await harness.pool.query(
      `INSERT INTO health_entries (
         id, pet_id, user_id, name, type, frequency, status,
         care_family, care_setting, care_planning, care_importance,
         importance_overridden, care_source, schedule_policy_version,
         provider_contact_id
       ) VALUES (
         $1, $2, $3, 'Annual check', 'vet_visit', 'yearly', 'active',
         'wellness_review', 'vet', 'planned', 'recommended',
         false, 'guardian_defined', 1, $4
       )`,
      [entryId, owner.petId, owner.userId, contactId],
    );

    const res = await peopleApi(harness.app, owner.token).deleteContact(contactId);
    expect(res.statusCode).toBe(409);
    expect(res.body.code).toBe('contact_in_use');
    expect(res.body.details.usages).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          kind: 'care_item_provider',
          id: entryId,
          pet_id: owner.petId,
        }),
      ]),
    );
  });
});
