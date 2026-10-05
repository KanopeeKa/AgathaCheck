import { jest } from '@jest/globals';
import { recordAccountDeviceSignIn } from '../../lib/account/accountDeviceLabels.js';
import * as notifications from '../../lib/account/accountSecurityNotifications.js';

describe('account device labels (A1)', () => {
  const userId = 'user-1';
  const email = 'user@example.com';

  function buildPool(handlers) {
    return {
      query: jest.fn(async (sql, params) => {
        for (const handler of handlers) {
          const result = await handler(sql, params);
          if (result !== undefined) return result;
        }
        throw new Error(`Unhandled SQL: ${sql}`);
      }),
    };
  }

  beforeEach(() => {
    jest.spyOn(notifications, 'emitAccountNewSignIn').mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('emits A1 for a new device label when the account already has history', async () => {
    const pool = buildPool([
      async (sql) => {
        if (sql.includes('FROM account_device_labels') && sql.includes('label = $2')) {
          return { rows: [] };
        }
        if (sql.includes('COUNT(*)') && sql.includes('account_device_labels')) {
          return { rows: [{ count: 1 }] };
        }
        if (sql.startsWith('INSERT INTO account_device_labels')) {
          return { rows: [] };
        }
      },
    ]);

    const result = await recordAccountDeviceSignIn(pool, {
      userId,
      email,
      label: 'Chrome on Windows',
      sessionFamilyId: 'family-1',
      isSignupSession: false,
    });

    expect(result.emittedA1).toBe(true);
    expect(notifications.emitAccountNewSignIn).toHaveBeenCalledTimes(1);
  });

  it('does not emit A1 when the label was seen within 90 days', async () => {
    const recent = new Date();
    const pool = buildPool([
      async (sql) => {
        if (sql.includes('label = $2')) {
          return {
            rows: [{
              id: 'row-1',
              label: 'Chrome on Windows',
              last_seen_at: recent,
            }],
          };
        }
        if (sql.includes('COUNT(*)')) {
          return { rows: [{ count: 2 }] };
        }
        if (sql.startsWith('UPDATE account_device_labels')) {
          return { rows: [] };
        }
      },
    ]);

    const result = await recordAccountDeviceSignIn(pool, {
      userId,
      email,
      label: 'Chrome on Windows',
      sessionFamilyId: 'family-1',
      isSignupSession: false,
    });

    expect(result.emittedA1).toBe(false);
    expect(notifications.emitAccountNewSignIn).not.toHaveBeenCalled();
  });

  it('does not emit A1 on signup session', async () => {
    const pool = buildPool([
      async (sql) => {
        if (sql.includes('label = $2')) return { rows: [] };
        if (sql.includes('COUNT(*)')) return { rows: [{ count: 0 }] };
        if (sql.startsWith('INSERT INTO account_device_labels')) return { rows: [] };
      },
    ]);

    const result = await recordAccountDeviceSignIn(pool, {
      userId,
      email,
      label: 'Safari on iOS',
      sessionFamilyId: 'family-1',
      isSignupSession: true,
    });

    expect(result.emittedA1).toBe(false);
    expect(notifications.emitAccountNewSignIn).not.toHaveBeenCalled();
  });
});
