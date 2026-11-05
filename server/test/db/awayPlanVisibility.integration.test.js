/**
 * Real-DB visibility and co-parent per-pet write matrix (away plans).
 */
import { randomUUID } from 'crypto';

import jwt from 'jsonwebtoken';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';
import { openStrictHarness } from './helpers/careHarness.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';

function tokenFor(userId, email) {
  return jwt.sign({ id: userId, email }, JWT_SECRET, { expiresIn: '1h' });
}

async function insertUser(pool, prefix) {
  const userId = randomUUID();
  const email = `${prefix}-${userId.slice(0, 8)}@away-vis.test`;
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', $3, 'Tester')`,
    [userId, email, prefix],
  );
  return { userId, email, token: tokenFor(userId, email) };
}

async function insertPet(pool, ownerId, name) {
  const petId = randomUUID();
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species, home_timezone)
     VALUES ($1, $2, $3, 'dog', 'UTC')`,
    [petId, ownerId, name],
  );
  return petId;
}

function collectPetIds(json) {
  const ids = new Set();
  const walk = (value) => {
    if (value == null || typeof value !== 'object') return;
    if (Array.isArray(value)) {
      value.forEach(walk);
      return;
    }
    for (const [key, v] of Object.entries(value)) {
      if ((key === 'pet_id' || key === 'petId') && typeof v === 'string') ids.add(v);
      if (key === 'pet_ids' && Array.isArray(v)) v.forEach((id) => ids.add(id));
      walk(v);
    }
  };
  walk(json);
  return ids;
}

function collectPetNames(json) {
  const names = new Set();
  const walk = (value) => {
    if (value == null || typeof value !== 'object') return;
    if (Array.isArray(value)) {
      value.forEach(walk);
      return;
    }
    for (const [key, v] of Object.entries(value)) {
      if (key === 'pet_name' || key === 'name') {
        if (typeof v === 'string') names.add(v);
      }
      walk(v);
    }
  };
  walk(json);
  return names;
}

describe('away plan visibility integration', () => {
  let harness;
  let traveller;
  let coParent;
  let petA;
  let petB;
  let petC;
  let absenceId;
  const today = todayCalendarIso();
  const startsOn = addCalendarDaysIso(today, 10);
  const endsOn = addCalendarDaysIso(today, 17);
  const secretNames = new Set(['WhiskersVis', 'PebbleVis']);

  beforeAll(async () => {
    harness = await openStrictHarness();
    traveller = await insertUser(harness.pool, 'Trav');
    coParent = await insertUser(harness.pool, 'Co');
    petA = await insertPet(harness.pool, traveller.userId, 'BuddyVis');
    petB = await insertPet(harness.pool, traveller.userId, 'WhiskersVis');
    petC = await insertPet(harness.pool, traveller.userId, 'PebbleVis');
    await harness.pool.query(
      `INSERT INTO pet_access (id, pet_id, user_id, role) VALUES ($1, $2, $3, 'co_parent')`,
      [randomUUID(), petA, coParent.userId],
    );

    const createRes = await request(harness.app)
      .post('/api/planned-absences')
      .set('Authorization', `Bearer ${traveller.token}`)
      .send({ pet_ids: [petA, petB, petC], starts_on: startsOn, ends_on: endsOn });
    expect(createRes.statusCode).toBe(201);
    absenceId = createRes.body.absence.id;
  }, 60000);

  afterAll(async () => {
    if (harness?.pool) {
      await harness.pool.query('DELETE FROM planned_absences WHERE id = $1', [absenceId]).catch(() => {});
      for (const petId of [petA, petB, petC]) {
        await harness.pool.query('DELETE FROM pets WHERE id = $1', [petId]).catch(() => {});
      }
      for (const u of [traveller, coParent]) {
        await harness.pool.query('DELETE FROM users WHERE id = $1', [u.userId]).catch(() => {});
      }
      await harness.pool.end();
    }
  });

  it('co-parent PATCH pet note on accessible pet succeeds', async () => {
    const res = await request(harness.app)
      .patch(`/api/planned-absences/${absenceId}/pets/${petA}`)
      .set('Authorization', `Bearer ${coParent.token}`)
      .send({ pet_note: 'Co-parent note' });
    expect(res.statusCode).toBe(200);
    expect(res.body.pet_id).toBe(petA);
    expect(res.body.pet_carer?.pet_note).toBe('Co-parent note');
  });

  it('co-parent PATCH on inaccessible pet returns 404', async () => {
    const res = await request(harness.app)
      .patch(`/api/planned-absences/${absenceId}/pets/${petB}`)
      .set('Authorization', `Bearer ${coParent.token}`)
      .send({ pet_note: 'nope' });
    expect(res.statusCode).toBe(404);
  });

  it('co-parent GET detail omits inaccessible pet ids and names', async () => {
    const res = await request(harness.app)
      .get(`/api/planned-absences/${absenceId}`)
      .set('Authorization', `Bearer ${coParent.token}`);
    expect(res.statusCode).toBe(200);
    const ids = collectPetIds(res.body);
    expect(ids.has(petA)).toBe(true);
    expect(ids.has(petB)).toBe(false);
    expect(ids.has(petC)).toBe(false);
    const names = collectPetNames(res.body);
    for (const n of secretNames) expect(names.has(n)).toBe(false);
  });

  for (const scope of ['upcoming', 'past', 'all']) {
    it(`co-parent GET list scope=${scope} runs real SQL without error`, async () => {
      const res = await request(harness.app)
        .get(`/api/planned-absences?scope=${scope}`)
        .set('Authorization', `Bearer ${coParent.token}`);
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  }

  it('co-parent cannot PATCH declarer-only absence route', async () => {
    const res = await request(harness.app)
      .patch(`/api/planned-absences/${absenceId}`)
      .set('Authorization', `Bearer ${coParent.token}`)
      .send({ title: 'hack' });
    expect(res.statusCode).toBe(404);
  });
});
