import { describe, expect, jest, test } from '@jest/globals';

import { revokeShareInvite } from '../../services/sharing/shareInviteRevokeService.js';

function buildInviteRow(overrides = {}) {
  return {
    id: 'inv-1',
    inviter_user_id: 'owner',
    invitee_user_id: 'invitee',
    status: 'pending',
    code: 'invite-code-9',
    ...overrides,
  };
}

function mockPoolForInvite(inviteRow) {
  const notificationUpdates = [];
  const client = {
    query: jest.fn(async (sql, params) => {
      if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') {
        return { command: sql };
      }
      if (sql.includes('UPDATE notifications')) {
        notificationUpdates.push({ sql, params });
        return { rowCount: 1, rows: [] };
      }
      if (sql.includes('pet_share_invites')) {
        return { rows: [inviteRow] };
      }
      if (sql.includes('pet_share_invite_pets')) {
        return { rows: [] };
      }
      return { rows: [] };
    }),
    release: jest.fn(),
  };
  return {
    pool: {
      connect: jest.fn(async () => client),
    },
    notificationUpdates,
  };
}

describe('revokeShareInvite notification resolve', () => {
  test('does not resolve notifications when invite code is null', async () => {
    const { pool, notificationUpdates } = mockPoolForInvite(buildInviteRow({ code: null }));
    const result = await revokeShareInvite(pool, { inviteId: 'inv-1', userId: 'owner' });
    expect(result.status).toBe('revoked');
    expect(notificationUpdates).toHaveLength(0);
  });

  test('resolves invite notification by referenceId when code is set', async () => {
    const { pool, notificationUpdates } = mockPoolForInvite(
      buildInviteRow({ code: 'invite-code-9' }),
    );
    await revokeShareInvite(pool, { inviteId: 'inv-1', userId: 'owner' });
    expect(notificationUpdates).toHaveLength(1);
    expect(notificationUpdates[0].params).toEqual([
      'invitee',
      'shareInviteReceived',
      'invite-code-9',
    ]);
    expect(notificationUpdates[0].sql).toMatch(/health_entry_id/);
  });
});
