import {
  normalizeEmail,
  inviteBlockedResponse,
  isInvitee,
  SHARE_INVITE_CREATE_DELIVERY,
} from '../../../services/sharing/shareInviteShared.js';

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

  it('SHARE_INVITE_CREATE_DELIVERY is opaque', () => {
    expect(SHARE_INVITE_CREATE_DELIVERY).toEqual({ status: 'queued' });
  });

  describe('isInvitee', () => {
    const invite = {
      invitee_email: 'invitee@example.com',
      invitee_user_id: 'user-a',
    };

    it('requires verified email matching invite', () => {
      expect(isInvitee(invite, 'user-a', 'invitee@example.com')).toBe(true);
      expect(isInvitee(invite, 'user-a', null)).toBe(false);
      expect(isInvitee(invite, 'user-a', 'other@example.com')).toBe(false);
    });

    it('rejects wrong user id when invitee_user_id is set', () => {
      expect(isInvitee(invite, 'user-b', 'invitee@example.com')).toBe(false);
    });

    it('allows email match when invitee_user_id is unset', () => {
      const openInvite = { invitee_email: 'new@example.com', invitee_user_id: null };
      expect(isInvitee(openInvite, 'user-new', 'new@example.com')).toBe(true);
    });
  });
});
