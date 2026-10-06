/**
 * Create pet share invite: orchestrates advisory lock, persistence, and delivery.
 */

import {
  findInviterEmail,
  findUserByEmail,
} from '../../db/sharing/shareInviteQueries.js';
import { lockShareInviteCreate } from '../../db/sharing/shareInviteLocks.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import { buildPetShareInvitationNewUserEmail } from '../../lib/email/templates/petShareInvitationNewUser.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { shareExpiryFromNow, DEFAULT_SHARE_EXPIRY_DAYS } from '../../lib/shareLinkPolicy.js';
import { createNotification } from '../../lib/notificationHelper.js';
import { normalizeShareAccessRole } from '../../lib/petSharing/permissions.js';
import { userCanSharePet } from '../../lib/petAccess.js';
import { sendTransactionalEmail } from '../mailService.js';
import { ShareCommandResult } from './shareCommandResult.js';
import {
  MAX_PET_IDS,
  normalizeEmail,
  validateShareInviteContact,
  classifyPetsForInvite,
  insertInviteWithCodeRetry,
  loadInviterName,
} from './shareInviteShared.js';

export async function createShareInvite(pool, {
  inviterUserId,
  inviteeEmail: rawEmail,
  petIds: rawPetIds,
  role: rawRole,
  locale,
  contactId: rawContactId,
}) {
  const inviteeEmail = normalizeEmail(rawEmail);
  const petIds = [...new Set((rawPetIds || []).filter(Boolean))];
  const role = normalizeShareAccessRole(rawRole);
  const contactId = rawContactId || null;

  if (!inviteeEmail) {
    return { error: 'invitee_email is required', status: 400 };
  }

  const contactError = await validateShareInviteContact(pool, contactId, inviterUserId, inviteeEmail);
  if (contactError) return contactError;
  if (petIds.length === 0 || petIds.length > MAX_PET_IDS) {
    return { error: 'pet_ids must contain between 1 and 20 items', status: 400 };
  }

  const inviterEmail = await findInviterEmail(pool, inviterUserId);
  if (inviterEmail && normalizeEmail(inviterEmail) === inviteeEmail) {
    return { error: 'You cannot invite yourself', status: 400 };
  }

  for (const petId of petIds) {
    if (!(await userCanSharePet(pool, petId, inviterUserId))) {
      return { error: 'You do not have permission to share one or more pets', status: 403 };
    }
  }

  const inviteeUser = await findUserByEmail(pool, inviteeEmail);
  const expiresAt = shareExpiryFromNow(DEFAULT_SHARE_EXPIRY_DAYS);

  let txResult;
  try {
    txResult = await withTransaction(pool, async (client) => {
      await lockShareInviteCreate(client, inviterUserId, inviteeEmail);

      const classified = await classifyPetsForInvite(client, {
        inviterUserId,
        inviteeEmail,
        inviteeUserId: inviteeUser?.id || null,
        petIds,
        role,
      });

      if (classified.replay) {
        return {
          status: 200,
          replayed: true,
          ...classified.replay,
          delivery: { email: 'skipped', notification: false },
        };
      }

      if (classified.error) {
        throw new ShareCommandResult({
          error: 'No pets available to invite for this email',
          status: 400,
          excluded: classified.excluded,
        });
      }

      const { includedPetIds, excluded } = classified;
      const { inviteId, code } = await insertInviteWithCodeRetry(client, {
        inviterUserId,
        inviteeEmail,
        inviteeUserId: inviteeUser?.id || null,
        role,
        expiresAt,
        includedPetIds,
        contactId,
      });

      const delivery = { email: 'skipped', notification: false };

      if (inviteeUser) {
        const inviterName = await loadInviterName(client, inviterUserId);
        const petNameRows = await client.query(
          'SELECT id, name FROM pets WHERE id = ANY($1::uuid[])',
          [includedPetIds],
        );
        const pets = petNameRows.rows.map((row) => ({ pet_id: row.id, pet_name: row.name }));
        for (const pet of pets) {
          await createNotification(client, {
            userId: inviteeUser.id,
            petId: pet.pet_id,
            petName: pet.pet_name,
            healthEntryId: code,
            title: 'Pet sharing invitation',
            message: `${inviterName} invited you to follow ${pet.pet_name}.`,
            type: 'shareInviteReceived',
          });
        }
        delivery.notification = true;
      }

      return {
        status: 201,
        invite_id: inviteId,
        code,
        included_pet_ids: includedPetIds,
        excluded,
        delivery,
        inviteeEmail,
        includedPetIds,
      };
    });
  } catch (err) {
    if (err instanceof ShareCommandResult) {
      return err.payload;
    }
    throw err;
  }

  if (txResult.replayed) {
    return txResult;
  }

  const committedResult = {
    status: txResult.status,
    invite_id: txResult.invite_id,
    code: txResult.code,
    included_pet_ids: txResult.included_pet_ids,
    excluded: txResult.excluded,
    delivery: txResult.delivery,
  };

  if (!inviteeUser) {
    try {
      const inviterName = await loadInviterName(pool, inviterUserId);
      const petNameRows = await pool.query(
        'SELECT id, name FROM pets WHERE id = ANY($1::uuid[])',
        [txResult.includedPetIds],
      );
      const pets = petNameRows.rows.map((row) => ({ pet_id: row.id, pet_name: row.name }));
      const { subject, text, html } = buildPetShareInvitationNewUserEmail({
        locale: resolveEmailLocale(locale),
        inviterName,
        pets,
        code: txResult.code,
      });
      await sendTransactionalEmail({ to: txResult.inviteeEmail, subject, text, html });
      committedResult.delivery.email = 'sent';
    } catch (mailErr) {
      console.error('Pet share invitation email failed for invite', txResult.invite_id, mailErr);
      committedResult.delivery.email = 'failed';
    }
  }

  return committedResult;
}
