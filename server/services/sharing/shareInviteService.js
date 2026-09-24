import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import {
  findExistingAccessForEmail,
  findInviteByCode,
  findInviteById,
  findInviterEmail,
  findPendingInviteForPetAndEmail,
  findPetAccessRole,
  findUserByEmail,
  insertInvite,
  insertInvitePets,
  insertPetAccess,
  setInviteeUserId,
  updateInviteStatus,
  upgradePetAccessRole,
} from '../../db/sharing/shareInviteQueries.js';
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

const MAX_PET_IDS = 20;

function generateInviteCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
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
  const excluded = [];
  const includedPetIds = [];

  for (const petId of petIds) {
    if (await findExistingAccessForEmail(pool, petId, inviteeEmail, inviteeUser?.id)) {
      excluded.push({ pet_id: petId, reason: 'already_has_access' });
      continue;
    }
    const pending = await findPendingInviteForPetAndEmail(pool, petId, inviteeEmail);
    if (pending) {
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
    return { error: 'No pets available to invite for this email', status: 400, excluded };
  }

  const expiresAt = shareExpiryFromNow(DEFAULT_SHARE_EXPIRY_DAYS);
  let inviteId;
  let code;
  let inserted = false;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (let attempt = 0; attempt < 5 && !inserted; attempt++) {
      code = generateInviteCode();
      inviteId = uuidv4();
      try {
        await insertInvite(client, {
          id: inviteId,
          inviterUserId,
          inviteeEmail,
          inviteeUserId: inviteeUser?.id || null,
          role,
          code,
          expiresAt,
        });
        await insertInvitePets(client, inviteId, includedPetIds);
        inserted = true;
      } catch (err) {
        if (err.code !== '23505') throw err;
      }
    }
    if (!inserted) {
      await client.query('ROLLBACK');
      return { error: 'Could not generate invite code', status: 500 };
    }
    await client.query('COMMIT');
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }

  const committedResult = {
    status: 201,
    invite_id: inviteId,
    code,
    included_pet_ids: includedPetIds,
    excluded,
    delivery: { email: 'skipped', notification: false },
  };

  try {
    const inviterName = await loadInviterName(pool, inviterUserId);
    const petNameRows = await pool.query(
      'SELECT id, name FROM pets WHERE id = ANY($1::uuid[])',
      [includedPetIds],
    );
    const pets = petNameRows.rows.map((row) => ({ pet_id: row.id, pet_name: row.name }));

    if (inviteeUser) {
      for (const pet of pets) {
        await createNotification(pool, {
          userId: inviteeUser.id,
          petId: pet.pet_id,
          petName: pet.pet_name,
          healthEntryId: code,
          title: 'Pet sharing invitation',
          message: `${inviterName} invited you to follow ${pet.pet_name}.`,
          type: 'shareInviteReceived',
        });
      }
      committedResult.delivery.notification = true;
    } else {
      try {
        const { subject, text, html } = buildPetShareInvitationNewUserEmail({
          locale: resolveEmailLocale(locale),
          inviterName,
          pets,
          code,
        });
        await sendTransactionalEmail({ to: inviteeEmail, subject, text, html });
        committedResult.delivery.email = 'sent';
      } catch (mailErr) {
        console.error('Pet share invitation email failed:', mailErr);
        committedResult.delivery.email = 'failed';
      }
    }
  } catch (deliveryErr) {
    console.error('Share invite post-commit delivery failed:', deliveryErr);
    committedResult.delivery = {
      email: 'failed',
      notification: false,
      delivery_error: true,
    };
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
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const invite = inviteId
      ? await findInviteById(client, inviteId, { forUpdate: true })
      : await findInviteByCode(client, code, { forUpdate: true });

    if (!invite) {
      await client.query('ROLLBACK');
      return { error: 'Invitation not found', status: 404 };
    }

    const accepterResult = await client.query(
      'SELECT first_name, last_name, email FROM users WHERE id = $1',
      [userId],
    );
    const accepter = accepterResult.rows[0] || {};
    const accepterEmail = accepter.email || userEmail;

    if (!isInvitee(invite, userId, accepterEmail)) {
      await client.query('ROLLBACK');
      return { error: 'This invitation was sent to a different email address', status: 403 };
    }

    if (invite.status === 'accepted') {
      await client.query('COMMIT');
      return {
        invite_id: invite.id,
        status: 'accepted',
        access_role: invite.role,
        pet_ids: invite.pets.map((p) => p.pet_id),
      };
    }

    const blocked = inviteBlockedResponse(invite);
    if (blocked) {
      await client.query('ROLLBACK');
      return blocked;
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

    await client.query('COMMIT');

    return {
      invite_id: invite.id,
      status: 'accepted',
      access_role: invite.role,
      pet_ids: grantedPetIds,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    if (err.code === '23505') {
      return { error: 'You already have access to one or more pets', status: 409 };
    }
    throw err;
  } finally {
    client.release();
  }
}

export async function declineShareInvite(pool, {
  inviteId,
  userId,
  userEmail,
}) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const invite = await findInviteById(client, inviteId, { forUpdate: true });
    if (!invite) {
      await client.query('ROLLBACK');
      return { error: 'Invitation not found', status: 404 };
    }

    const declinerResult = await client.query(
      'SELECT first_name, last_name, email FROM users WHERE id = $1',
      [userId],
    );
    const decliner = declinerResult.rows[0] || {};
    const declinerEmail = decliner.email || userEmail;

    if (!isInvitee(invite, userId, declinerEmail)) {
      await client.query('ROLLBACK');
      return { error: 'This invitation was sent to a different email address', status: 403 };
    }

    if (invite.status === 'accepted') {
      await client.query('ROLLBACK');
      return { error: 'Invitation was already accepted', status: 409 };
    }

    if (invite.status === 'declined') {
      await client.query('COMMIT');
      return { invite_id: invite.id, status: 'declined' };
    }

    const blocked = inviteBlockedResponse(invite);
    if (blocked) {
      await client.query('ROLLBACK');
      return blocked;
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

    await client.query('COMMIT');

    return {
      invite_id: invite.id,
      status: invite.status === 'pending' ? 'declined' : invite.status,
    };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }
}

export async function revokeShareInvite(pool, { inviteId, userId }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const invite = await findInviteById(client, inviteId, { forUpdate: true });
    if (!invite) {
      await client.query('ROLLBACK');
      return { error: 'Invitation not found', status: 404 };
    }
    if (invite.inviter_user_id !== userId) {
      await client.query('ROLLBACK');
      return { error: 'Forbidden', status: 403 };
    }
    if (invite.status !== 'pending') {
      await client.query('ROLLBACK');
      return { error: 'Invitation is no longer pending', status: 409 };
    }
    await updateInviteStatus(client, invite.id, 'revoked');
    await client.query('COMMIT');
    return { invite_id: invite.id, status: 'revoked' };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }
}
