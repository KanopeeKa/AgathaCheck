import { describe, expect, test } from '@jest/globals';

import { resolveNotificationsByType } from '../../lib/notificationHelper.js';
import {
  NOTIFICATION_KIND_RELATIONSHIP,
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
} from '../../lib/notificationKind.js';

describe('resolveNotificationsByType', () => {
  test('resolves relationship invite rows (not only administrative)', async () => {
    const updates = [];
    const pool = {
      query: async (sql, params) => {
        updates.push({ sql, params });
        return { rows: [], rowCount: 1 };
      },
    };
    await resolveNotificationsByType(pool, {
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
});
