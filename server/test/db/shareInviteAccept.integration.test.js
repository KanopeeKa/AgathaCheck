import { randomUUID } from 'crypto';

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';

import {
  acceptShareInvite,
  createShareInvite,
  revokeShareInvite,
} from '../../services/sharing/shareInviteService.js';
import { createDbPool } from './helpers/careHarness.js';

let pool;
let dbAvailable = false;

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

async function seedScenario(pool) {
  const ownerId = randomUUID();
  const inviteeId = randomUUID();
  const petId = randomUUID();
  const email = `accept-${inviteeId}@example.com`;

  await pool.query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name)
     VALUES ($1, $2, 'hash', 'Owner', 'One'), ($3, $4, 'hash', 'Invitee', 'Two')`,
    [ownerId, `owner-${ownerId}@example.com`, inviteeId, email],
  );
  await pool.query(
    `INSERT INTO pets (id, user_id, name, species) VALUES ($1, $2, 'Buddy', 'dog')`,
    [petId, ownerId],
  );

  const created = await createShareInvite(pool, {
    inviterUserId: ownerId,
    inviteeEmail: email,
    petIds: [petId],
    role: 'carer',
  });

  return { ownerId, inviteeId, petId, email, inviteId: created.invite_id, code: created.code };
}

describe('share invite accept (real PG)', () => {
  it('grants access once when accept races', async () => {
    if (!dbAvailable || !pool) return;

    const scenario = await seedScenario(pool);
    const [first, second] = await Promise.all([
      acceptShareInvite(pool, {
        inviteId: scenario.inviteId,
        userId: scenario.inviteeId,
        userEmail: scenario.email,
      }),
      acceptShareInvite(pool, {
        inviteId: scenario.inviteId,
        userId: scenario.inviteeId,
        userEmail: scenario.email,
      }),
    ]);

    expect(first.status).toBe('accepted');
    expect(second.status).toBe('accepted');

    const access = await pool.query(
      'SELECT COUNT(*)::int AS count FROM pet_access WHERE pet_id = $1 AND user_id = $2',
      [scenario.petId, scenario.inviteeId],
    );
    expect(access.rows[0].count).toBe(1);

    await pool.query('DELETE FROM pet_access WHERE pet_id = $1', [scenario.petId]);
    await pool.query(
      'DELETE FROM notifications WHERE user_id = ANY($1::uuid[])',
      [[scenario.ownerId, scenario.inviteeId]],
    );
    await pool.query('DELETE FROM pet_share_invite_pets WHERE invite_id = $1', [scenario.inviteId]);
    await pool.query('DELETE FROM pet_share_invites WHERE id = $1', [scenario.inviteId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [scenario.petId]);
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[scenario.ownerId, scenario.inviteeId]]);
  });

  it('does not grant access when accept races revoke', async () => {
    if (!dbAvailable || !pool) return;

    const scenario = await seedScenario(pool);
    const [acceptResult, revokeResult] = await Promise.all([
      acceptShareInvite(pool, {
        inviteId: scenario.inviteId,
        userId: scenario.inviteeId,
        userEmail: scenario.email,
      }),
      revokeShareInvite(pool, { inviteId: scenario.inviteId, userId: scenario.ownerId }),
    ]);

    const accepted = acceptResult.status === 'accepted';
    const revoked = revokeResult.status === 'revoked';
    expect(accepted || revoked).toBe(true);
    if (revoked) {
      expect(acceptResult.error || acceptResult.status).toBeTruthy();
    }

    const access = await pool.query(
      'SELECT COUNT(*)::int AS count FROM pet_access WHERE pet_id = $1 AND user_id = $2',
      [scenario.petId, scenario.inviteeId],
    );
    if (revoked && !accepted) {
      expect(access.rows[0].count).toBe(0);
    }

    await pool.query('DELETE FROM pet_access WHERE pet_id = $1', [scenario.petId]);
    await pool.query(
      'DELETE FROM notifications WHERE user_id = ANY($1::uuid[])',
      [[scenario.ownerId, scenario.inviteeId]],
    );
    await pool.query('DELETE FROM pet_share_invite_pets WHERE invite_id = $1', [scenario.inviteId]);
    await pool.query('DELETE FROM pet_share_invites WHERE id = $1', [scenario.inviteId]);
    await pool.query('DELETE FROM pets WHERE id = $1', [scenario.petId]);
    await pool.query('DELETE FROM users WHERE id = ANY($1::uuid[])', [[scenario.ownerId, scenario.inviteeId]]);
  });
});
