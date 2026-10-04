import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import { createShareInvite } from '../../services/sharing/shareInviteService.js';
import { createDbPool } from './helpers/careHarness.js';

let pool;
let dbAvailable = false;

async function seedOwnerWithPets(pool, { ownerId, petIds }) {
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Share', 'Owner')`,
    [ownerId, `share-owner-${ownerId}@example.com`],
  );
  for (const petId of petIds) {
    await pool.query(
      `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, $3, 'dog')`,
      [petId, ownerId, `Pet-${petId.slice(0, 8)}`],
    );
  }
}

async function seedInvitee(pool, inviteeId, email) {
  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Share', 'Invitee')`,
    [inviteeId, email],
  );
}

beforeAll(async () => {
  pool = createDbPool();
  try {
    await pool.query('SELECT 1 FROM pet_share_invites LIMIT 1');
    dbAvailable = true;
  } catch {
    dbAvailable = false;
    await pool.end();
    pool = null;
  }
}, 30000);

afterAll(async () => {
  await pool?.end();
});

describe('share invite create (real PG)', () => {
  it('replays identical pending invite from the same inviter with replayed: true', async () => {
    if (!dbAvailable || !pool) return;

    const ownerId = randomUUID();
    const inviteeId = randomUUID();
    const petId = randomUUID();
    const email = `invitee-${inviteeId}@example.com`;
    await seedOwnerWithPets(pool, { ownerId, petIds: [petId] });
    await seedInvitee(pool, inviteeId, email);

    const first = await createShareInvite(pool, {
      inviterUserId: ownerId,
      inviteeEmail: email,
      petIds: [petId],
      role: 'carer',
    });
    expect(first.status).toBe(201);

    const notificationsBefore = await pool.query(
      'SELECT COUNT(*)::int AS count FROM notifications WHERE user_id = $1',
      [inviteeId],
    );

    const replay = await createShareInvite(pool, {
      inviterUserId: ownerId,
      inviteeEmail: email,
      petIds: [petId],
      role: 'carer',
    });
    expect(replay).toMatchObject({
      status: 200,
      replayed: true,
      invite_id: first.invite_id,
      code: first.code,
    });

    const inviteCount = await pool.query(
      'SELECT COUNT(*)::int AS count FROM pet_share_invites WHERE inviter_user_id = $1',
      [ownerId],
    );
    expect(inviteCount.rows[0].count).toBe(1);

    const notificationsAfter = await pool.query(
      'SELECT COUNT(*)::int AS count FROM notifications WHERE user_id = $1',
      [inviteeId],
    );
    expect(notificationsAfter.rows[0].count).toBe(notificationsBefore.rows[0].count);

    await pool.query('DELETE FROM notifications WHERE user_id = $1', [inviteeId]);
    await pool.query('DELETE FROM pet_share_invite_pets WHERE invite_id = $1', [first.invite_id]);
    await pool.query('DELETE FROM pet_share_invites WHERE id = $1', [first.invite_id]);
    await pool.query('DELETE FROM pets WHERE user_id = $1', [ownerId]);
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[ownerId, inviteeId]]);
  });

  it('serializes concurrent identical creates to one invite and one replay', async () => {
    if (!dbAvailable || !pool) return;

    const ownerId = randomUUID();
    const petId = randomUUID();
    const email = `concurrent-${randomUUID()}@example.com`;
    await seedOwnerWithPets(pool, { ownerId, petIds: [petId] });

    const payload = {
      inviterUserId: ownerId,
      inviteeEmail: email,
      petIds: [petId],
      role: 'carer',
    };

    const [a, b] = await Promise.all([
      createShareInvite(pool, payload),
      createShareInvite(pool, payload),
    ]);

    const statuses = [a.status, b.status].sort();
    expect(statuses).toEqual([200, 201]);
    const created = a.status === 201 ? a : b;
    const replayed = a.status === 200 ? a : b;
    expect(replayed.replayed).toBe(true);
    expect(replayed.invite_id).toBe(created.invite_id);

    const inviteCount = await pool.query(
      'SELECT COUNT(*)::int AS count FROM pet_share_invites WHERE inviter_user_id = $1',
      [ownerId],
    );
    expect(inviteCount.rows[0].count).toBe(1);

    await pool.query('DELETE FROM pet_share_invite_pets WHERE invite_id = $1', [created.invite_id]);
    await pool.query('DELETE FROM pet_share_invites WHERE id = $1', [created.invite_id]);
    await pool.query('DELETE FROM pets WHERE user_id = $1', [ownerId]);
    await pool.query('DELETE FROM users WHERE id = $1', [ownerId]);
  });
});
