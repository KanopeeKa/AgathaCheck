import { buildNotificationDeepLink } from '../lib/checkDueNotifications.js';

describe('buildNotificationDeepLink', () => {
  it('returns view-entry path when pet and entry ids are present', () => {
    expect(buildNotificationDeepLink('pet-1', 'entry-1')).toBe(
      '/pet/pet-1/events/entry-1',
    );
  });

  it('returns null when pet id is missing', () => {
    expect(buildNotificationDeepLink(null, 'entry-1')).toBeNull();
    expect(buildNotificationDeepLink('', 'entry-1')).toBeNull();
  });

  it('returns null when entry id is missing', () => {
    expect(buildNotificationDeepLink('pet-1', null)).toBeNull();
    expect(buildNotificationDeepLink('pet-1', '')).toBeNull();
  });
});
