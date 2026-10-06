import { normalizeEmail, inviteBlockedResponse } from '../../../services/sharing/shareInviteShared.js';

describe('shareInviteShared', () => {
  it('normalizeEmail trims and lowercases', () => {
    expect(normalizeEmail('  User@Example.COM ')).toBe('user@example.com');
  });

  it('inviteBlockedResponse flags revoked invites', () => {
    expect(inviteBlockedResponse({ status: 'revoked' })).toEqual({
      status: 410,
      error: 'Invitation is no longer valid',
    });
  });
});
