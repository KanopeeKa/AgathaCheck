import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import { findUserByEmail } from '../../db/sharing/shareInviteQueries.js';
import { buildHouseholdInvitationEmail } from '../email/templates/householdInvitation.js';
import { resolveEmailLocale } from '../email/locale.js';
import { createNotification, userDisplayName } from '../notificationHelper.js';
import { canEditContact } from '../people/access.js';
import { logPeopleInviteEvent, tryLinkInviteContact } from '../people/inviteContactLink.js';
import { isShareLinkExpired, shareExpiryFromNow } from '../shareLinkPolicy.js';
import { sendTransactionalEmail } from '../../services/mailService.js';
import {
  getHouseholdMembership,
  userIsHouseholdOrganiser,
} from './authz.js';
import {
  HOUSEHOLD_TIER_FULL,
  isHouseholdTier,
  normalizeMemberTier,
} from './constants.js';

export const HOUSEHOLD_INVITE_EXPIRY_DAYS = 14;

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

async function loadInviterName(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return userDisplayName(result.rows[0] || {});
}

async function loadInviteByCode(db, code) {
  const result = await db.query(
    `SELECT i.*, h.name AS household_name
     FROM household_invites i
     INNER JOIN households h ON h.id = i.household_id
     WHERE i.code = $1`,
    [code],
  );
  return result.rows[0] || null;
}

async function loadInviteById(db, inviteId) {
  const result = await db.query(
    `SELECT i.*, h.name AS household_name
     FROM household_invites i
     INNER JOIN households h ON h.id = i.household_id
     WHERE i.id = $1`,
    [inviteId],
  );
  return result.rows[0] || null;
}

async function isHouseholdMemberByEmail(db, householdId, email) {
  const result = await db.query(
    `SELECT 1
     FROM household_members hm
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hm.household_id = $1 AND LOWER(u.email) = LOWER($2)
     LIMIT 1`,
    [householdId, email],
  );
  return result.rows.length > 0;
}

async function validateContactForInvite(db, contactId, inviterUserId, inviteeEmail) {
  if (!contactId) return null;
  if (!(await canEditContact(db, contactId, inviterUserId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const contactResult = await db.query(
    `SELECT email, inactive_at FROM people_contacts WHERE id = $1`,
    [contactId],
  );
  const contact = contactResult.rows[0];
  if (!contact || contact.inactive_at != null) {
    return { error: 'Contact is not available', status: 400 };
  }
  const contactEmail = normalizeEmail(contact.email);
  if (contactEmail && contactEmail !== normalizeEmail(inviteeEmail)) {
    return { error: 'Contact email must match invitee_email', status: 400 };
  }
  return null;
}

export async function createHouseholdInvite(pool, {
  householdId,
  inviterUserId,
  inviteeEmail: rawEmail,
  accessTier: rawTier,
  isOrganiser: rawOrganiser,
  contactId,
  locale,
}) {
  if (!(await userIsHouseholdOrganiser(pool, householdId, inviterUserId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const inviteeEmail = normalizeEmail(rawEmail);
  if (!inviteeEmail) {
    return { error: 'invitee_email is required', status: 400 };
  }

  const isOrganiser = Boolean(rawOrganiser);
  let accessTier = rawTier || HOUSEHOLD_TIER_FULL;
  if (!isHouseholdTier(accessTier) && !isOrganiser) {
    return { error: 'Invalid access_tier', status: 400 };
  }
  accessTier = normalizeMemberTier({ accessTier, isOrganiser });

  const contactError = await validateContactForInvite(pool, contactId, inviterUserId, inviteeEmail);
  if (contactError) return contactError;

  const inviterEmailResult = await pool.query('SELECT email FROM users WHERE id = $1', [inviterUserId]);
  const inviterEmail = inviterEmailResult.rows[0]?.email;
  if (inviterEmail && normalizeEmail(inviterEmail) === inviteeEmail) {
    return { error: 'You cannot invite yourself', status: 400 };
  }

  if (await isHouseholdMemberByEmail(pool, householdId, inviteeEmail)) {
    return { error: 'User is already a member', status: 409 };
  }

  const inviteeUser = await findUserByEmail(pool, inviteeEmail);
  if (inviteeUser) {
    const existing = await getHouseholdMembership(pool, householdId, inviteeUser.id);
    if (existing) {
      return { error: 'User is already a member', status: 409 };
    }
  }

  const pending = await pool.query(
    `SELECT id FROM household_invites
     WHERE household_id = $1 AND LOWER(invitee_email) = LOWER($2)
       AND status = 'pending' AND expires_at > NOW()
     LIMIT 1`,
    [householdId, inviteeEmail],
  );
  if (pending.rows.length > 0) {
    return { error: 'A pending invite already exists for this email', status: 409 };
  }

  const inviteId = uuidv4();
  const code = generateInviteCode();
  const expiresAt = shareExpiryFromNow(HOUSEHOLD_INVITE_EXPIRY_DAYS);

  await pool.query(
    `INSERT INTO household_invites (
       id, household_id, inviter_user_id, invitee_email, invitee_user_id,
       access_tier, is_organiser, contact_id, code, status, expires_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
    [
      inviteId,
      householdId,
      inviterUserId,
      inviteeEmail,
      inviteeUser?.id || null,
      accessTier,
      isOrganiser,
      contactId || null,
      code,
      INVITE_PENDING,
      expiresAt,
    ],
  );

  logPeopleInviteEvent('household_invite_created', {
    invite_id: inviteId,
    household_id: householdId,
    inviter_user_id: inviterUserId,
    contact_id: contactId || undefined,
  });

  const delivery = { email: 'skipped', notification: false };

  if (inviteeUser) {
    const inviterName = await loadInviterName(pool, inviterUserId);
    const household = await pool.query('SELECT name FROM households WHERE id = $1', [householdId]);
    await createNotification(pool, {
      userId: inviteeUser.id,
      title: 'Household invitation',
      message: `${inviterName} invited you to join ${household.rows[0]?.name || 'a household'}.`,
      type: 'householdInviteReceived',
      healthEntryId: code,
    });
    delivery.notification = true;
  } else {
    try {
      const inviterName = await loadInviterName(pool, inviterUserId);
      const household = await pool.query('SELECT name FROM households WHERE id = $1', [householdId]);
      const { subject, text, html } = buildHouseholdInvitationEmail({
        locale: resolveEmailLocale(locale),
        inviterName,
        householdName: household.rows[0]?.name || 'Household',
        code,
      });
      await sendTransactionalEmail({ to: inviteeEmail, subject, text, html });
      delivery.email = 'sent';
    } catch (mailErr) {
      console.error('Household invitation email failed for invite', inviteId, mailErr);
      delivery.email = 'failed';
    }
  }

  return {
    status: 201,
    invite_id: inviteId,
    code,
    expires_at: expiresAt.toISOString(),
    delivery,
  };
}

export async function getHouseholdInvitePreview(pool, code) {
  const invite = await loadInviteByCode(pool, code);
  if (!invite) return { error: 'Not found', status: 404 };
  const blocked = inviteBlockedResponse(invite);
  if (blocked) return blocked;

  const inviterName = await loadInviterName(pool, invite.inviter_user_id);
  return {
    invite_id: invite.id,
    code: invite.code,
    household_id: invite.household_id,
    household_name: invite.household_name,
    inviter_name: inviterName,
    access_tier: invite.access_tier,
    is_organiser: invite.is_organiser === true,
    invitee_email: invite.invitee_email,
    expires_at: invite.expires_at?.toISOString?.() || String(invite.expires_at),
  };
}

async function resolveAccepterEmail(pool, userId, userEmail) {
  const result = await pool.query(
    'SELECT email FROM users WHERE id = $1',
    [userId],
  );
  return result.rows[0]?.email || userEmail || null;
}

export async function acceptHouseholdInvite(pool, {
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
  const accepterEmail = await resolveAccepterEmail(pool, userId, userEmail);
  if (!isInvitee(invite, userId, accepterEmail)) {
    return { error: 'Forbidden', status: 403 };
  }

  const existing = await getHouseholdMembership(pool, invite.household_id, userId);
  if (existing) {
    return { error: 'User is already a member', status: 409 };
  }

  await pool.query(
    `INSERT INTO household_members (
       household_id, user_id, access_tier, is_organiser, joined_at
     ) VALUES ($1, $2, $3, $4, NOW())`,
    [invite.household_id, userId, invite.access_tier, invite.is_organiser],
  );

  await pool.query(
    `UPDATE household_invites
     SET status = $2, invitee_user_id = $3, responded_at = NOW()
     WHERE id = $1`,
    [invite.id, INVITE_ACCEPTED, userId],
  );

  await tryLinkInviteContact(pool, invite.contact_id, userId, {
    inviteId: invite.id,
    source: 'household',
  });

  logPeopleInviteEvent('household_invite_accepted', {
    invite_id: invite.id,
    household_id: invite.household_id,
    user_id: userId,
    contact_id: invite.contact_id || undefined,
  });

  return {
    household_id: invite.household_id,
    status: INVITE_ACCEPTED,
    access_tier: invite.access_tier,
    is_organiser: invite.is_organiser === true,
  };
}

export async function declineHouseholdInvite(pool, {
  inviteId,
  code,
  userId,
  userEmail,
}) {
  const invite = code
    ? await loadInviteByCode(pool, code)
    : await loadInviteById(pool, inviteId);
  if (!invite) return { error: 'Not found', status: 404 };
  const declinerEmail = await resolveAccepterEmail(pool, userId, userEmail);
  if (!isInvitee(invite, userId, declinerEmail)) {
    return { error: 'Forbidden', status: 403 };
  }
  if (invite.status === INVITE_ACCEPTED) {
    return { error: 'Invitation was already accepted', status: 409 };
  }
  if (invite.status === INVITE_DECLINED) {
    return { invite_id: invite.id, status: INVITE_DECLINED };
  }
  const blocked = inviteBlockedResponse(invite);
  if (blocked) return blocked;

  await pool.query(
    `UPDATE household_invites
     SET status = $2, invitee_user_id = $3, responded_at = NOW()
     WHERE id = $1`,
    [invite.id, INVITE_DECLINED, userId],
  );

  return { invite_id: invite.id, status: INVITE_DECLINED };
}

export async function revokeHouseholdInvite(pool, { householdId, inviteId, userId }) {
  if (!(await userIsHouseholdOrganiser(pool, householdId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const invite = await loadInviteById(pool, inviteId);
  if (!invite || invite.household_id !== householdId) {
    return { error: 'Not found', status: 404 };
  }
  if (invite.status !== INVITE_PENDING) {
    return { error: 'Only pending invites can be revoked', status: 400 };
  }

  await pool.query(
    `UPDATE household_invites
     SET status = $2, responded_at = NOW()
     WHERE id = $1`,
    [inviteId, INVITE_REVOKED],
  );

  logPeopleInviteEvent('household_invite_revoked', {
    invite_id: inviteId,
    household_id: householdId,
    inviter_user_id: userId,
  });

  return { invite_id: inviteId, status: INVITE_REVOKED };
}
