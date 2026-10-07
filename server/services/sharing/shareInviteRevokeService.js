/**
 * Revoke a pending share invite (inviter only).
 */
import {
  findInviteById,
  updateInviteStatus,
} from '../../db/sharing/shareInviteQueries.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import { resolveNotifications } from '../../lib/notificationHelper.js';
import { ShareCommandResult } from './shareCommandResult.js';

export async function revokeShareInvite(pool, { inviteId, userId }) {
  try {
    return await withTransaction(pool, async (client) => {
      const invite = await findInviteById(client, inviteId, { forUpdate: true });
      if (!invite) {
        throw new ShareCommandResult({ error: 'Invitation not found', status: 404 });
      }
      if (invite.inviter_user_id !== userId) {
        throw new ShareCommandResult({ error: 'Forbidden', status: 403 });
      }
      if (invite.status !== 'pending') {
        throw new ShareCommandResult({ error: 'Invitation is no longer pending', status: 409 });
      }
      await updateInviteStatus(client, invite.id, 'revoked');
      if (invite.invitee_user_id) {
        await resolveNotifications(client, {
          userId: invite.invitee_user_id,
          type: 'shareInviteReceived',
          referenceId: invite.code,
        });
      }
      return { invite_id: invite.id, status: 'revoked' };
    });
  } catch (err) {
    if (err instanceof ShareCommandResult) {
      return err.payload;
    }
    throw err;
  }
}
