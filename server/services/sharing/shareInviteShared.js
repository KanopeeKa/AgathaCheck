/**
 * Shared helpers for pet share invite orchestration (classification, codes, contact validation).
 */

import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import {
  findExistingAccessForEmail,
  findPendingInviteDetailsForPetAndEmail,
  loadInvitePetIds,
  insertInvite,
  insertInvitePets,
} from '../../db/sharing/shareInviteQueries.js';
import { isShareLinkExpired } from '../../lib/shareLinkPolicy.js';
import { userDisplayName } from '../../lib/notificationHelper.js';
import { canEditContact } from '../../lib/people/access.js';
import { ShareCommandResult } from './shareCommandResult.js';

export const MAX_PET_IDS = 20;

function generateInviteCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
}

export function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function petSetEqual(a, b) {
  if (a.length !== b.length) return false;
  const left = [...a].sort();
  const right = [...b].sort();
  return left.every((value, index) => value === right[index]);
}

export function inviteBlockedResponse(invite) {
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

export async function loadInviterName(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return userDisplayName(result.rows[0] || {});
}

export function isInvitee(invite, userId, userEmail) {
  if (invite.invitee_user_id && invite.invitee_user_id === userId) return true;
  if (userEmail && normalizeEmail(invite.invitee_email) === normalizeEmail(userEmail)) {
    return true;
  }
  return false;
}

/**
 * @param {import('pg').PoolClient} client
 */
export async function classifyPetsForInvite(client, {
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

export async function insertInviteWithCodeRetry(client, {
  inviterUserId,
  inviteeEmail,
  inviteeUserId,
  role,
  expiresAt,
  includedPetIds,
  contactId,
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
        contactId,
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

export async function validateShareInviteContact(db, contactId, inviterUserId, inviteeEmail) {
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
