import {
  NOTIFICATION_KIND_ACCOUNT,
  NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
  NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
} from '../../lib/notificationKind.js';
import {
  applyAccountSecurityFeedback,
  emitAccountDeletionRequestedEmail,
  emitAccountPasswordChanged,
  resolveAccountSecurityNotificationsOnSecureAccount,
} from '../../lib/account/accountSecurityNotifications.js';

function mockPool(rowsByQuery) {
  const updates = [];
  return {
    updates,
    query: async (sql, params) => {
      if (sql.includes('SELECT id, type, kind, resolved_at, created_at')) {
        const id = params[0];
        const row = rowsByQuery.get(id);
        if (!row) return { rows: [] };
        return { rows: [row] };
      }
      if (sql.includes('UPDATE notifications SET resolved_at')) {
        updates.push({ sql, params });
        return { rows: [] };
      }
      if (sql.includes('UPDATE notifications') && sql.includes('type = ANY')) {
        updates.push({ sql, params });
        return { rows: [] };
      }
      throw new Error(`Unexpected query: ${sql}`);
    },
  };
}

describe('account security notifications (AC-ACS)', () => {
  const userId = 'user-1';

  it('AC-ACS-2: this_was_me resolves A1', async () => {
    const pool = mockPool(
      new Map([
        [
          'n1',
          {
            id: 'n1',
            type: NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
            kind: NOTIFICATION_KIND_ACCOUNT,
            resolved_at: null,
            created_at: new Date(),
          },
        ],
      ]),
    );
    const outcome = await applyAccountSecurityFeedback(
      pool,
      userId,
      'n1',
      'this_was_me',
    );
    expect(outcome.status).toBe(200);
    expect(pool.updates).toHaveLength(1);
  });

  it('AC-ACS-5: password change creates inbox notification row', async () => {
    const createCalls = [];
    const pool = {
      query: async (sql) => {
        if (sql.includes('INSERT INTO notifications')) {
          createCalls.push(sql);
        }
        return { rows: [] };
      },
    };
    await emitAccountPasswordChanged(pool, {
      userId,
      email: 'user@example.com',
    });
    expect(createCalls.length).toBeGreaterThan(0);
  });

  it('A2 rejects this_was_me', async () => {
    const pool = mockPool(
      new Map([
        [
          'n2',
          {
            id: 'n2',
            type: NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
            kind: NOTIFICATION_KIND_ACCOUNT,
            resolved_at: null,
            created_at: new Date(),
          },
        ],
      ]),
    );
    const outcome = await applyAccountSecurityFeedback(
      pool,
      userId,
      'n2',
      'this_was_me',
    );
    expect(outcome.status).toBe(400);
  });

  it('AC-ACS-10: A6 deletion notice is email-only helper', async () => {
    await expect(
      emitAccountDeletionRequestedEmail({ email: 'user@example.com' }),
    ).resolves.toBeUndefined();
  });

  it('secure-account flow resolves A1 and A2 rows (AC-ACS-3)', async () => {
    const pool = mockPool(new Map());
    await resolveAccountSecurityNotificationsOnSecureAccount(pool, userId, 'n-secure');
    expect(pool.updates).toHaveLength(1);
    expect(pool.updates[0].params[2]).toEqual([
      NOTIFICATION_TYPE_ACCOUNT_NEW_SIGN_IN,
      NOTIFICATION_TYPE_ACCOUNT_PASSWORD_CHANGED,
    ]);
  });
});
