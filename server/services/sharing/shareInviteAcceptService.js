/**
 * Accept a pending share invite and grant pet access.
 */
import { v4 as uuidv4 } from 'uuid';
import {
  findInviteById,
  findInviteByCode,
  findPetAccessRole,
  insertPetAccess,
  setInviteeUserId,
  updateInviteStatus,
  upgradePetAccessRole,
} from '../../db/sharing/shareInviteQueries.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import {
  createNotification,
  resolveAdministrativeNotifications,
  userDisplayName,
} from '../../lib/notificationHelper.js';
import { CARER_ROLE, CO_PARENT_ROLE } from '../../lib/petAccess.js';
import { tryLinkInviteContact } from '../../lib/people/inviteContactLink.js';
import { ShareCommandResult } from './shareCommandResult.js';
import { inviteBlockedResponse, isInvitee } from './shareInviteShared.js';

export async function acceptShareInvite(pool, {
  inviteId,
  code,
  userId,
  userEmail,
}) {
  try {
    return await withTransaction(pool, async (client) => {
      const invite = inviteId
        ? await findInviteById(client, inviteId, { forUpdate: true })
        : await findInviteByCode(client, code, { forUpdate: true });

      if (!invite) {
        throw new ShareCommandResult({ error: 'Invitation not found', status: 404 });
      }

      const accepterResult = await client.query(
        'SELECT first_name, last_name, email FROM users WHERE id = $1',
        [userId],
      );
      const accepter = accepterResult.rows[0] || {};
      const accepterEmail = accepter.email || userEmail;

      if (!isInvitee(invite, userId, accepterEmail)) {
        throw new ShareCommandResult({
          error: 'This invitation was sent to a different email address',
          status: 403,
        });
      }

      if (invite.status === 'accepted') {
        return {
          invite_id: invite.id,
          status: 'accepted',
          access_role: invite.role,
          pet_ids: invite.pets.map((p) => p.pet_id),
        };
      }

      const blocked = inviteBlockedResponse(invite);
      if (blocked) {
        throw new ShareCommandResult(blocked);
      }

      if (!invite.invitee_user_id) {
        await setInviteeUserId(client, invite.id, userId);
      }

      const grantedPetIds = [];
      for (const pet of invite.pets) {
        const existingRole = await findPetAccessRole(client, pet.pet_id, userId);
        if (existingRole) {
          if (invite.role === CO_PARENT_ROLE && existingRole === CARER_ROLE) {
            await upgradePetAccessRole(client, pet.pet_id, userId, CO_PARENT_ROLE);
          }
          grantedPetIds.push(pet.pet_id);
          continue;
        }

        await insertPetAccess(client, {
          id: uuidv4(),
          petId: pet.pet_id,
          userId,
          role: invite.role,
          invitedBy: invite.inviter_user_id,
        });
        grantedPetIds.push(pet.pet_id);
      }

      if (invite.status === 'pending') {
        await updateInviteStatus(client, invite.id, 'accepted');
      }

      await tryLinkInviteContact(client, invite.contact_id, userId, {
        inviteId: invite.id,
        source: 'pet_share',
      });

      const accepterName = userDisplayName(accepter);
      const petNames = invite.pets.map((p) => p.pet_name).filter(Boolean).join(', ') || 'pets';

      await resolveAdministrativeNotifications(client, {
        userId,
        type: 'shareInviteReceived',
      });

      await createNotification(client, {
        userId: invite.inviter_user_id,
        petId: invite.pets[0]?.pet_id || null,
        petName: invite.pets[0]?.pet_name || null,
        title: 'Invitation accepted',
        message: `${accepterName} accepted your invitation to follow ${petNames}.`,
        type: 'shareInviteAccepted',
      });

      return {
        invite_id: invite.id,
        status: 'accepted',
        access_role: invite.role,
        pet_ids: grantedPetIds,
      };
    });
  } catch (err) {
    const payload = err instanceof ShareCommandResult ? err.payload : null;
    if (payload) return payload;
    if (err.code === '23505') {
      return { error: 'You already have access to one or more pets', status: 409 };
    }
    throw err;
  }
}
