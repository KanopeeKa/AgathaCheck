import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { createNotification, userDisplayName } from '../notificationHelper.js';
import { NOTIFICATION_TYPE_ABSENCE_GUEST_GRANTED } from '../notificationKind.js';
import { isShareLinkExpired, shareExpiryFromNow } from '../shareLinkPolicy.js';
import {
  GUEST_GRANT_ACTIVE,
  GUEST_GRANT_REVOKED,
  userCanGrantAbsenceGuestForPet,
} from './absenceGuestGrants.js';

const PLANNED_ABSENCE_STATUS_ACTIVE = 'active';
const PLANNED_ABSENCE_STATUS_CANCELLED = 'cancelled';

export const INVITE_PENDING = 'pending';
export const INVITE_ACCEPTED = 'accepted';
export const INVITE_DECLINED = 'declined';
export const INVITE_REVOKED = 'revoked';
export const INVITE_EXPIRED = 'expired';

function generateInviteCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function inviteBlockedResponse(invite) {
  if (invite.status === INVITE_REVOKED) {
    return { status: 410, error: 'Invitation is no longer valid' };
  }
  if (invite.status === INVITE_DECLINED) {
    return { status: 410, error: 'Invitation was declined' };
  }
  if (invite.status === INVITE_ACCEPTED) {
    return { status: 410, error: 'Invitation was already accepted' };
  }
  if (invite.status === INVITE_EXPIRED || isShareLinkExpired(invite.expires_at)) {
    return { status: 410, error: 'Invitation has expired' };
  }
  return null;
}

function isInvitee(invite, userId, userEmail) {
  if (invite.invitee_user_id && invite.invitee_user_id === userId) return true;
  if (userEmail && normalizeEmail(invite.invitee_email) === normalizeEmail(userEmail)) {
    return true;
  }
  return false;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} absenceId
 */
async function loadAbsence(db, absenceId) {
  const result = await db.query('SELECT * FROM planned_absences WHERE id = $1', [absenceId]);
  return result.rows[0] || null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} absenceId
 */
async function loadAbsencePetRows(db, absenceId) {
  const result = await db.query(
    `SELECT pet_id, contact_id FROM planned_absence_pets WHERE planned_absence_id = $1`,
    [absenceId],
  );
  return result.rows;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} db
 * @param {string} contactId
 */
async function loadContact(db, contactId) {
  const result = await db.query(
    `SELECT id, email, linked_user_id, inactive_at FROM people_contacts WHERE id = $1`,
    [contactId],
  );
  return result.rows[0] || null;
}

async function loadInviterName(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return userDisplayName(result.rows[0] || {});
}

/**
 * @param {import('pg').Pool} pool
 */
export async function createAbsenceCarerInvite(pool, {
  absenceId,
  inviterUserId,
  contactId,
  petIds: rawPetIds,
}) {
  if (!contactId) {
    return { error: 'contact_id is required', status: 400 };
  }
  const absence = await loadAbsence(pool, absenceId);
  if (!absence) return { error: 'Not found', status: 404 };
  if (absence.status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { error: 'Cannot invite for a cancelled absence', status: 400 };
  }

  const petRows = await loadAbsencePetRows(pool, absenceId);
  const absencePetIds = petRows.map((row) => row.pet_id);
  const contactPetIds = petRows
    .filter((row) => row.contact_id === contactId)
    .map((row) => row.pet_id);
  if (contactPetIds.length === 0) {
    return { error: 'Contact is not assigned as carer on this absence', status: 400 };
  }

  let targetPetIds = contactPetIds;
  if (rawPetIds != null) {
    const requested = [...new Set((rawPetIds || []).filter(Boolean))];
    targetPetIds = requested.filter((id) => contactPetIds.includes(id));
    if (targetPetIds.length === 0) {
      return { error: 'pet_ids must be absence pets covered by this contact', status: 400 };
    }
  }

  for (const petId of targetPetIds) {
    if (!(await userCanGrantAbsenceGuestForPet(pool, petId, inviterUserId))) {
      return { error: 'Forbidden', status: 403 };
    }
  }

  const contact = await loadContact(pool, contactId);
  if (!contact || contact.inactive_at != null) {
    return { error: 'Contact is not available', status: 400 };
  }
  const inviteeEmail = normalizeEmail(contact.email);
  if (!inviteeEmail) {
    return { error: 'Contact must have an email for an app invite', status: 400 };
  }

  const inviterEmailResult = await pool.query('SELECT email FROM users WHERE id = $1', [inviterUserId]);
  const inviterEmail = inviterEmailResult.rows[0]?.email;
  if (inviterEmail && normalizeEmail(inviterEmail) === inviteeEmail) {
    return { error: 'You cannot invite yourself', status: 400 };
  }

  const inviteId = uuidv4();
  const code = generateInviteCode();
  const expiresAt = shareExpiryFromNow();

  await pool.query(
    `INSERT INTO planned_absence_carer_invites (
       id, planned_absence_id, contact_id, inviter_user_id,
       invitee_email, invitee_user_id, code, status, expires_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
    [
      inviteId,
      absenceId,
      contactId,
      inviterUserId,
      inviteeEmail,
      contact.linked_user_id || null,
      code,
      INVITE_PENDING,
      expiresAt,
    ],
  );

  for (const petId of targetPetIds) {
    await pool.query(
      `INSERT INTO planned_absence_carer_invite_pets (invite_id, pet_id) VALUES ($1, $2)`,
      [inviteId, petId],
    );
  }

  return {
    status: 201,
    invite_id: inviteId,
    code,
    pet_ids: targetPetIds,
    expires_at: expiresAt.toISOString(),
  };
}

async function loadInviteByCode(db, code) {
  const result = await db.query(
    `SELECT i.*, pa.user_id AS absence_owner_user_id, pa.starts_on, pa.ends_on, pa.timezone, pa.status AS absence_status
     FROM planned_absence_carer_invites i
     INNER JOIN planned_absences pa ON pa.id = i.planned_absence_id
     WHERE i.code = $1`,
    [code],
  );
  return result.rows[0] || null;
}

async function loadInviteById(db, inviteId) {
  const result = await db.query(
    `SELECT i.*, pa.user_id AS absence_owner_user_id, pa.starts_on, pa.ends_on, pa.timezone, pa.status AS absence_status
     FROM planned_absence_carer_invites i
     INNER JOIN planned_absences pa ON pa.id = i.planned_absence_id
     WHERE i.id = $1`,
    [inviteId],
  );
  return result.rows[0] || null;
}

async function loadInvitePetIds(db, inviteId) {
  const result = await db.query(
    'SELECT pet_id FROM planned_absence_carer_invite_pets WHERE invite_id = $1',
    [inviteId],
  );
  return result.rows.map((row) => row.pet_id);
}

export async function getAbsenceCarerInvitePreview(pool, code) {
  const invite = await loadInviteByCode(pool, code);
  if (!invite) return { error: 'Not found', status: 404 };
  const blocked = inviteBlockedResponse(invite);
  if (blocked) return blocked;
  if (invite.absence_status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 410, error: 'Absence is no longer active' };
  }
  const petIds = await loadInvitePetIds(pool, invite.id);
  const inviterName = await loadInviterName(pool, invite.inviter_user_id);
  return {
    invite_id: invite.id,
    code: invite.code,
    inviter_name: inviterName,
    starts_on: invite.starts_on,
    ends_on: invite.ends_on,
    timezone: invite.timezone,
    pet_ids: petIds,
    invitee_email: invite.invitee_email,
  };
}

async function notifyAbsenceOwnerGrant(pool, {
  absenceOwnerUserId,
  granterUserId,
  petIds,
  absenceId,
}) {
  if (!absenceOwnerUserId || absenceOwnerUserId === granterUserId) return;
  const granterName = await loadInviterName(pool, granterUserId);
  for (const petId of petIds) {
    await createNotification(pool, {
      userId: absenceOwnerUserId,
      petId,
      type: NOTIFICATION_TYPE_ABSENCE_GUEST_GRANTED,
      title: 'Absence access granted',
      message: `${granterName} granted temporary absence access.`,
    });
  }
}

async function linkContactToUser(pool, contactId, userId) {
  await pool.query(
    `UPDATE people_contacts
     SET linked_user_id = $2, updated_at = NOW()
     WHERE id = $1 AND linked_user_id IS NULL`,
    [contactId, userId],
  );
}

export async function acceptAbsenceCarerInvite(pool, {
  inviteId,
  code,
  userId,
  userEmail,
}) {
  const invite = code
    ? await loadInviteByCode(pool, code)
    : await loadInviteById(pool, inviteId);
  if (!invite) return { error: 'Not found', status: 404 };
  const blocked = inviteBlockedResponse(invite);
  if (blocked) return blocked;
  if (!isInvitee(invite, userId, userEmail)) {
    return { error: 'Forbidden', status: 403 };
  }
  if (invite.absence_status === PLANNED_ABSENCE_STATUS_CANCELLED) {
    return { status: 410, error: 'Absence is no longer active' };
  }

  const petIds = await loadInvitePetIds(pool, invite.id);
  if (petIds.length === 0) {
    return { error: 'Invite has no pets', status: 400 };
  }

  await pool.query(
    `UPDATE planned_absence_carer_invites
     SET status = $2, invitee_user_id = $3, responded_at = NOW()
     WHERE id = $1`,
    [invite.id, INVITE_ACCEPTED, userId],
  );

  for (const petId of petIds) {
    await pool.query(
      `INSERT INTO planned_absence_guest_grants (
         id, planned_absence_id, pet_id, grantee_user_id, granted_by_user_id,
         contact_id, invite_id, status
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (planned_absence_id, pet_id, grantee_user_id)
       DO UPDATE SET status = $8, revoked_at = NULL, granted_by_user_id = EXCLUDED.granted_by_user_id`,
      [
        uuidv4(),
        invite.planned_absence_id,
        petId,
        userId,
        invite.inviter_user_id,
        invite.contact_id,
        invite.id,
        GUEST_GRANT_ACTIVE,
      ],
    );
  }

  await linkContactToUser(pool, invite.contact_id, userId);
  await notifyAbsenceOwnerGrant(pool, {
    absenceOwnerUserId: invite.absence_owner_user_id,
    granterUserId: invite.inviter_user_id,
    petIds,
    absenceId: invite.planned_absence_id,
  });

  return {
    absence_id: invite.planned_absence_id,
    pet_ids: petIds,
    status: INVITE_ACCEPTED,
  };
}

export async function revokeAbsenceCarerInvite(pool, { inviteId, userId }) {
  const invite = await loadInviteById(pool, inviteId);
  if (!invite) return { error: 'Not found', status: 404 };
  if (invite.status !== INVITE_PENDING) {
    return { error: 'Only pending invites can be revoked', status: 400 };
  }
  const petIds = await loadInvitePetIds(pool, invite.id);
  for (const petId of petIds) {
    if (!(await userCanGrantAbsenceGuestForPet(pool, petId, userId))) {
      return { error: 'Forbidden', status: 403 };
    }
  }
  await pool.query(
    `UPDATE planned_absence_carer_invites
     SET status = $2, responded_at = NOW()
     WHERE id = $1`,
    [inviteId, INVITE_REVOKED],
  );
  return { status: INVITE_REVOKED };
}

export async function revokeAbsenceGuestGrant(pool, { grantId, userId }) {
  const result = await pool.query(
    `SELECT g.*, pa.user_id AS absence_owner_user_id
     FROM planned_absence_guest_grants g
     INNER JOIN planned_absences pa ON pa.id = g.planned_absence_id
     WHERE g.id = $1`,
    [grantId],
  );
  const grant = result.rows[0];
  if (!grant) return { error: 'Not found', status: 404 };
  if (grant.status !== GUEST_GRANT_ACTIVE) {
    return { error: 'Grant is not active', status: 400 };
  }
  const canRevoke = await userCanGrantAbsenceGuestForPet(pool, grant.pet_id, userId)
    || grant.grantee_user_id === userId
    || grant.absence_owner_user_id === userId;
  if (!canRevoke) return { error: 'Forbidden', status: 403 };
  await pool.query(
    `UPDATE planned_absence_guest_grants
     SET status = $2, revoked_at = NOW()
     WHERE id = $1`,
    [grantId, GUEST_GRANT_REVOKED],
  );
  return { status: GUEST_GRANT_REVOKED };
}

export async function loadUserTimezone(pool, userId) {
  const result = await pool.query('SELECT timezone FROM users WHERE id = $1', [userId]);
  return result.rows[0]?.timezone || 'UTC';
}
