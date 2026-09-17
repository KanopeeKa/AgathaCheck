import crypto from 'crypto';
import { v4 as uuidv4 } from 'uuid';

import {
  activateShareLink,
  deleteShareLink,
  findAccepterUser,
  findOwnerFirstName,
  findPetAccessForHide,
  findPetAccessRole,
  findPetById,
  insertPetAccessFromLink,
  insertShareLink,
  listHiddenPets,
  loadShareLinkByCode,
  loadShareLinkForAccept,
  updatePetAccessHidden,
} from '../../db/sharing/shareLinkQueries.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import {
  isShareLinkExpired,
  normalizeShareExpiryDays,
  shareExpiryFromNow,
} from '../../lib/shareLinkPolicy.js';
import { buildSharePreviewResponse } from '../../lib/sharePreview.js';
import { normalizeShareAccessRole } from '../../lib/petSharing/permissions.js';
import { CARER_ROLE, PET_ACCESS_ROLES, userCanSharePet } from '../../lib/petAccess.js';

function generateShareCode() {
  return crypto.randomBytes(6).toString('base64url').slice(0, 8);
}

function shareLinkBlockedResponse(link) {
  if (link.status === 'revoked') {
    return { status: 410, error: 'Share link is no longer valid' };
  }
  if (isShareLinkExpired(link.expires_at)) {
    return { status: 410, error: 'Share link has expired' };
  }
  return null;
}

export async function createLink(pool, { userId, petId, expiresInDays: rawExpiresInDays, accessRole: rawAccessRole }) {
  if (!petId) {
    return { error: 'pet_id is required', status: 400 };
  }
  // Align with petAccessRoutes: 403 for auth failures (not 404).
  if (!(await userCanSharePet(pool, petId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const expiresInDays = normalizeShareExpiryDays(rawExpiresInDays);
  const expiresAt = shareExpiryFromNow(expiresInDays);
  const accessRole = normalizeShareAccessRole(rawAccessRole ?? CARER_ROLE);

  let code;
  let linkId;
  let inserted = false;
  for (let attempt = 0; attempt < 5 && !inserted; attempt++) {
    code = generateShareCode();
    linkId = uuidv4();
    try {
      await insertShareLink(pool, {
        id: linkId,
        petId,
        code,
        createdBy: userId,
        expiresAt,
        accessRole,
      });
      inserted = true;
    } catch (err) {
      if (err.code !== '23505') throw err;
    }
  }

  if (!inserted) {
    return { error: 'Could not generate share code', status: 500 };
  }

  return {
    status: 201,
    share_code: code,
    link_id: linkId,
    expires_at: expiresAt.toISOString(),
    expires_in_days: expiresInDays,
    access_role: accessRole,
  };
}

export async function revokeLink(pool, { userId, linkId }) {
  const rows = await deleteShareLink(pool, linkId, userId);
  if (rows.length === 0) {
    return { error: 'Share link not found', status: 404 };
  }
  return { status: 200, message: 'Share link deleted' };
}

export async function getPreview(pool, code) {
  const link = await loadShareLinkByCode(pool, code);
  if (!link) {
    return { error: 'Share link not found or expired', status: 404 };
  }
  const blocked = shareLinkBlockedResponse(link);
  if (blocked) {
    return blocked;
  }

  const petRow = await findPetById(pool, link.pet_id);
  if (!petRow) {
    return { error: 'Pet not found', status: 404 };
  }

  const owner = await findOwnerFirstName(pool, petRow.user_id);
  return buildSharePreviewResponse(link, petRow, owner);
}

export async function acceptLink(pool, { userId, code }) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const link = await loadShareLinkForAccept(client, code);
    if (!link) {
      await client.query('ROLLBACK');
      return { error: 'Share link not found or expired', status: 404 };
    }
    const blocked = shareLinkBlockedResponse(link);
    if (blocked) {
      await client.query('ROLLBACK');
      return blocked;
    }
    if (link.owner_id === userId) {
      await client.query('ROLLBACK');
      return { error: 'You already own this pet', status: 400 };
    }

    const existingRole = await findPetAccessRole(client, link.pet_id, userId);
    if (existingRole) {
      await client.query('COMMIT');
      return {
        pet_id: link.pet_id,
        access_role: PET_ACCESS_ROLES.includes(existingRole) ? existingRole : existingRole,
        status: existingRole,
      };
    }

    if (link.status === 'active') {
      if (link.claimed_by === userId) {
        await client.query('COMMIT');
        const grantedRole = link.access_role || CARER_ROLE;
        return {
          pet_id: link.pet_id,
          access_role: grantedRole,
          status: grantedRole,
        };
      }
      await client.query('ROLLBACK');
      return { error: 'This share link has already been used', status: 410 };
    }

    const accessId = uuidv4();
    const grantedRole = link.access_role || CARER_ROLE;
    await insertPetAccessFromLink(client, {
      id: accessId,
      petId: link.pet_id,
      userId,
      role: grantedRole,
      invitedBy: link.created_by,
      shareLinkId: link.id,
    });

    await activateShareLink(client, link.id, userId);

    const accepter = await findAccepterUser(client, userId);
    const accepterName = userDisplayName(accepter);

    await createNotification(client, {
      userId: link.owner_id,
      petId: link.pet_id,
      petName: link.pet_name,
      title: 'Share accepted',
      message: `${accepterName} is now following ${link.pet_name}. You can remove them at any time from the Sharing section.`,
      type: 'general',
    });

    await client.query('COMMIT');
    return {
      pet_id: link.pet_id,
      access_role: grantedRole,
      status: grantedRole,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return { error: 'You already have access to this pet', status: 409 };
    }
    throw err;
  } finally {
    client.release();
  }
}

export async function hidePet(pool, { userId, petId, hidden }) {
  const role = await findPetAccessForHide(pool, petId, userId);
  if (!role) {
    return { error: 'Only shared or fostered pets can be hidden', status: 403 };
  }
  await updatePetAccessHidden(pool, { hidden, petId, userId, role });
  return { message: hidden ? 'Pet hidden' : 'Pet unhidden' };
}

export async function listHidden(pool, userId) {
  const rows = await listHiddenPets(pool, userId);
  return rows;
}
