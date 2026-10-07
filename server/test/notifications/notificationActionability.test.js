import { describe, expect, test } from '@jest/globals';

import {
  notificationNeedsResponse,
  NOTIFICATION_TYPES_NEEDING_RESPONSE,
} from '../../lib/notifications/notificationActionability.js';
import {
  NOTIFICATION_KIND_ADMINISTRATIVE,
  NOTIFICATION_KIND_RELATIONSHIP,
  NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
} from '../../lib/notificationKind.js';

describe('notificationActionability', () => {
  test('share invite needs response when unresolved', () => {
    expect(
      notificationNeedsResponse(
        NOTIFICATION_KIND_RELATIONSHIP,
        NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
        {},
      ),
    ).toBe(true);
  });

  test('informational admin session does not need response', () => {
    expect(
      notificationNeedsResponse(
        NOTIFICATION_KIND_ADMINISTRATIVE,
        'sessionStartingSoon',
        {},
      ),
    ).toBe(false);
  });

  test('resolved invite does not need response', () => {
    expect(
      notificationNeedsResponse(
        NOTIFICATION_KIND_RELATIONSHIP,
        NOTIFICATION_TYPE_SHARE_INVITE_RECEIVED,
        { resolvedAt: new Date() },
      ),
    ).toBe(false);
  });

  test('matrix includes pending placement types', () => {
    expect(NOTIFICATION_TYPES_NEEDING_RESPONSE.has('pendingFosterPlacementReceived')).toBe(
      true,
    );
  });

  test('foster org invitation is informational (not needs-response)', () => {
    expect(NOTIFICATION_TYPES_NEEDING_RESPONSE.has('fosterInvitationReceived')).toBe(
      false,
    );
  });
});
