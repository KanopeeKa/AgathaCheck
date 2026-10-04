import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import {
  findExistingAccessForEmail,
  findInviteByCode,
  findInviteById,
  findInviterEmail,
  findPendingInviteDetailsForPetAndEmail,
  findPendingInviteForPetAndEmail,
  findPetAccessRole,
  findUserByEmail,
  insertInvite,
  insertInvitePets,
  insertPetAccess,
  loadInvitePetIds,
  setInviteeUserId,
  updateInviteStatus,
  upgradePetAccessRole,
} from '../../db/sharing/shareInviteQueries.js';
import { lockShareInviteCreate } from '../../db/sharing/shareInviteLocks.js';
import { withTransaction } from '../../lib/db/withTransaction.js';
import { buildPetShareInvitationNewUserEmail } from '../../lib/email/templates/petShareInvitationNewUser.js';
import { resolveEmailLocale } from '../../lib/email/locale.js';
import { isShareLinkExpired, shareExpiryFromNow, DEFAULT_SHARE_EXPIRY_DAYS } from '../../lib/shareLinkPolicy.js';
import {
  createNotification,
  resolveAdministrativeNotifications,
  userDisplayName,
} from '../../lib/notificationHelper.js';
import { normalizeShareAccessRole } from '../../lib/petSharing/permissions.js';
import { CARER_ROLE, CO_PARENT_ROLE, userCanSharePet } from '../../lib/petAccess.js';
import { sendTransactionalEmail } from '../mailService.js';
import { ShareCommandResult } from './shareCommandResult.js';

const MAX_PET_IDS = 20;

function generateInviteCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function petSetEqual(a, b) {
  if (a.length !== b.length) return false;
  const left = [...a].sort();
  const right = [...b].sort();
  return left.every((value, index) => value === right[index]);
}

function inviteBlockedResponse(invite) {
  if (invite.status === 'revoked') {
    return { status: 410, error: 'Invitation is no longer valid' };
  }
  if (invite.status === 'declined') {
    return { status: 410, error: 'Invitation was declined' };
  }
  if (invite.status === 'accepted') {
    return { status: 410, error: 'Invitation was already accepted' };
  }
  if (invite.status === 'expired' || isShareLinkExpired(invite.expires_at)) {
    return { status: 410, error: 'Invitation has expired' };
  }
  return null;
}

async function loadInviterName(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return userDisplayName(result.rows[0] || {});
}

function isInvitee(invite, userId, userEmail) {
  if (invite.invitee_user_id && invite.invitee_user_id === userId) return true;
  if (userEmail && normalizeEmail(invite.invitee_email) === normalizeEmail(userEmail)) {
    return true;
  }
  return false;
}

/**
 * @param {import('pg').PoolClient} client
 */
async function classifyPetsForInvite(client, {
  inviterUserId,
  inviteeEmail,
  inviteeUserId,
  petIds,
  role,
}) {
  const excluded = [];
  const includedPetIds = [];
  const inviteCache = new Map();

  for (const petId of petIds) {
    if (await findExistingAccessForEmail(client, petId, inviteeEmail, inviteeUserId)) {
      excluded.push({ pet_id: petId, reason: 'already_has_access' });
      continue;
    }
    const pending = await findPendingInviteDetailsForPetAndEmail(client, petId, inviteeEmail);
    if (pending) {
      if (!inviteCache.has(pending.id)) {
        const petIdsOnInvite = await loadInvitePetIds(client, pending.id);
        inviteCache.set(pending.id, {
          id: pending.id,
          code: pending.code,
          role: pending.role,
          inviter_user_id: pending.inviter_user_id,
          petIds: petIdsOnInvite,
        });
      }
      excluded.push({
        pet_id: petId,
        reason: 'pending_invite_exists',
        existing_invite_id: pending.id,
      });
      continue;
    }
    includedPetIds.push(petId);
  }

  if (includedPetIds.length === 0) {
    const pendingOnly = excluded.filter((row) => row.reason === 'pending_invite_exists');
    if (pendingOnly.length === petIds.length) {
      const inviteIds = new Set(pendingOnly.map((row) => row.existing_invite_id));
      if (inviteIds.size === 1) {
        const inviteId = pendingOnly[0].existing_invite_id;
        const invite = inviteCache.get(inviteId);
        if (
          invite
          && invite.inviter_user_id === inviterUserId
          && invite.role === role
          && petSetEqual(invite.petIds, petIds)
        ) {
          return {
            replay: {
              invite_id: invite.id,
              code: invite.code,
              included_pet_ids: [...petIds],
              excluded: [],
            },
          };
        }
      }
    }
    return { error: true, excluded };
  }

  return { includedPetIds, excluded };
}

async function insertInviteWithCodeRetry(client, {
  inviterUserId,
  inviteeEmail,
  inviteeUserId,
  role,
  expiresAt,
  includedPetIds,
}) {
  let inviteId;
  let code;
  for (let attempt = 0; attempt < 5; attempt++) {
    const savepoint = `invite_code_sp_${attempt}`;
    await client.query(`SAVEPOINT ${savepoint}`);
    code = generateInviteCode();
    inviteId = uuidv4();
    try {
      await insertInvite(client, {
        id: inviteId,
        inviterUserId,
        inviteeEmail,
        inviteeUserId,
        role,
        code,
        expiresAt,
      });
      await insertInvitePets(client, inviteId, includedPetIds);
      await client.query(`RELEASE SAVEPOINT ${savepoint}`);
      return { inviteId, code };
    } catch (err) {
      await client.query(`ROLLBACK TO SAVEPOINT ${savepoint}`);
      if (err.code !== '23505') throw err;
    }
  }
  throw new ShareCommandResult({ error: 'Could not generate invite code', status: 500 });
}

export async function createShareInvite(pool, {
  inviterUserId,
  inviteeEmail: rawEmail,
  petIds: rawPetIds,
  role: rawRole,
  locale,
}) {
  const inviteeEmail = normalizeEmail(rawEmail);
  const petIds = [...new Set((rawPetIds || []).filter(Boolean))];
  const role = normalizeShareAccessRole(rawRole);

  if (!inviteeEmail) {
    return { error: 'invitee_email is required', status: 400 };
  }
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
      return { invite_id: invite.id, status: 'revoked' };
    });
  } catch (err) {
    if (err instanceof ShareCommandResult) {
      return err.payload;
    }
    throw err;
  }
}
