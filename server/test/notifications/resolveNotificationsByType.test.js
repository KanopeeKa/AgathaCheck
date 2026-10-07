import { describe, expect, test } from '@jest/globals';

import { resolveNotifications } from '../../lib/notificationHelper.js';
import {
  NOTIFICATION_KIND_RELATIONSHIP,
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
} from '../../lib/notificationKind.js';

describe('resolveNotifications', () => {
  test('resolves relationship invite rows (not only administrative)', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        updates.push({ sql, params });
        return { rows: [], rowCount: 1 };
      },
    };
    await resolveNotifications(pool, {
      userId: 'u1',
      type: NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
    });
    expect(updates).toHaveLength(1);
    expect(updates[0].sql).not.toMatch(/kind\s*=/i);
    expect(updates[0].params).toEqual([
      'u1',
      NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
    ]);
  });

  test('scopes resolve to invite reference in health_entry_id', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        updates.push({ sql, params });
        return { rows: [], rowCount: 1 };
      },
    };
    await resolveNotifications(pool, {
      userId: 'u1',
      type: NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
      referenceId: 'invite-code-9',
    });
    expect(updates[0].params).toEqual([
      'u1',
      NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
      'invite-code-9',
    ]);
    expect(updates[0].sql).toMatch(/health_entry_id/);
  });

  test('referenceId limits resolve to one invite when types match', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        updates.push({ sql, params });
        return { rows: [], rowCount: 1 };
      },
    };
    await resolveNotifications(pool, {
      userId: 'u1',
      type: NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
      referenceId: 'code-a',
    });
    expect(updates).toHaveLength(1);
    expect(updates[0].params).toContain('code-a');
    expect(updates[0].sql).toMatch(/health_entry_id\s*=\s*\$3/i);
  });
});
