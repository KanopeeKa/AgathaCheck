/**
 * Read-only invite preview by public code.
 */
import { findInviteByCode } from '../../db/sharing/shareInviteQueries.js';
import { inviteBlockedResponse } from './shareInviteShared.js';

export async function getInvitePreview(pool, code) {
  const invite = await findInviteByCode(pool, code);
  if (!invite) {
    return { error: 'Invitation not found', status: 404 };
  }
  const blocked = inviteBlockedResponse(invite);
  if (blocked) return blocked;

  return {
    invite_id: invite.id,
    code: invite.code,
    role: invite.role,
    status: invite.status,
    expires_at: invite.expires_at?.toISOString?.() || String(invite.expires_at),
    inviter_name: invite.inviter_name?.trim() || 'Someone',
    pets: invite.pets,
  };
}
