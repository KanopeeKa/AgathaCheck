/**
 * Decline a pending share invite.
 */
import {
  findInviteById,
  updateInviteStatus,
} from '../../db/sharing/shareInviteQueries.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import {
  createNotification,
  resolveAdministrativeNotifications,
  userDisplayName,
} from '../../lib/notificationHelper.js';
import { ShareCommandResult } from './shareCommandResult.js';
import { inviteBlockedResponse, isInvitee } from './shareInviteShared.js';

export async function declineShareInvite(pool, {
  inviteId,
  userId,
  userEmail,
}) {
  try {
    return await withTransaction(pool, async (client) => {
      const invite = await findInviteById(client, inviteId, { forUpdate: true });
      if (!invite) {
        throw new ShareCommandResult({ error: 'Invitation not found', status: 404 });
      }

      const declinerResult = await client.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const decliner = declinerResult.rows[0] || {};
      const declinerEmail = decliner.email || userEmail;

      if (!isInvitee(invite, userId, declinerEmail)) {
        throw new ShareCommandResult({
          error: 'This invitation was sent to a different email address',
          status: 403,
        });
      }

      if (invite.status === 'accepted') {
        throw new ShareCommandResult({ error: 'Invitation was already accepted', status: 409 });
      }

      if (invite.status === 'declined') {
        return { invite_id: invite.id, status: 'declined' };
      }

      const blocked = inviteBlockedResponse(invite);
      if (blocked) {
        throw new ShareCommandResult(blocked);
      }

      await updateInviteStatus(client, invite.id, 'declined');

      const declinerName = userDisplayName(decliner);
      const petNames = invite.pets.map((p) => p.pet_name).filter(Boolean).join(', ') || 'pets';

      await resolveAdministrativeNotifications(client, {
        userId,
        type: 'shareInviteReceived',
        referenceId: invite.code,
      });

      await createNotification(client, {
        userId: invite.inviter_user_id,
        petId: invite.pets[0]?.pet_id || null,
        petName: invite.pets[0]?.pet_name || null,
        title: 'Invitation declined',
        message: `${declinerName} declined your invitation to follow ${petNames}.`,
        type: 'shareInviteDeclined',
      });

      return {
        invite_id: invite.id,
        status: invite.status === 'pending' ? 'declined' : invite.status,
      };
    });
  } catch (err) {
    if (err instanceof ShareCommandResult) {
      return err.payload;
    }
    throw err;
  }
}
