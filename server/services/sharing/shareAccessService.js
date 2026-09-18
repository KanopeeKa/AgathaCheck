import {
  deleteAccessForTargetUser,
  deleteSharedAccessForUser,
  findPetName,
  findPetNameAndOwner,
  findUserDisplayFields,
  listAccessForPet,
  listAccessForPetIds,
  listPendingInvitesForPetIds,
  listShareLinksForPet,
  updateAccessRole,
} from '../../db/sharing/shareAccessQueries.js';
import { listPendingInvitesForPet } from '../../db/sharing/shareInviteQueries.js';
import { createNotification, userDisplayName } from '../../lib/notificationHelper.js';
import {
  CARER_ROLE,
  CO_PARENT_ROLE,
  userCanSharePet,
  userIsOwnerOrCoParent,
} from '../../lib/petAccess.js';

function mapAccessRow(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    role: row.role,
    invited_by: row.invited_by || null,
    created_at: row.created_at,
    user: {
      first_name: row.first_name || '',
      last_name: row.last_name || '',
      email: row.email || '',
      category: row.category || 'pet_carer',
      bio: row.bio || '',
      photo_url: row.photo_url || '',
    },
  };
}

function mapPendingInviteRow(row) {
  return {
    id: row.id,
    inviter_user_id: row.inviter_user_id,
    invitee_email: row.invitee_email,
    invitee_user_id: row.invitee_user_id || null,
    role: row.role,
    code: row.code,
    status: row.status,
    created_at: row.created_at,
    expires_at: row.expires_at,
    pet_id: row.pet_id,
  };
}

export async function listAccessForPets(pool, userId, petIds) {
  const uniquePetIds = [...new Set((petIds || []).filter(Boolean))];
  const allowedPetIds = [];
  for (const petId of uniquePetIds) {
    if (await userCanSharePet(pool, petId, userId)) {
      allowedPetIds.push(petId);
    }
  }

  const [accessRows, inviteRows] = await Promise.all([
    listAccessForPetIds(pool, allowedPetIds),
    listPendingInvitesForPetIds(pool, allowedPetIds),
  ]);

  const accessByPet = new Map(allowedPetIds.map((id) => [id, []]));
  for (const row of accessRows) {
    accessByPet.get(row.pet_id)?.push(mapAccessRow(row));
  }

  const invitesByPet = new Map(allowedPetIds.map((id) => [id, []]));
  for (const row of inviteRows) {
    invitesByPet.get(row.pet_id)?.push(mapPendingInviteRow(row));
  }

  return {
    pets: allowedPetIds.map((petId) => ({
      pet_id: petId,
      access: accessByPet.get(petId) || [],
      pending_invites: invitesByPet.get(petId) || [],
    })),
  };
}

export async function listPendingInvitesForPetAccess(pool, userId, petId) {
  if (!(await userCanSharePet(pool, petId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const rows = await listPendingInvitesForPet(pool, petId);
  return {
    invites: rows.map((row) => ({
      id: row.id,
      invitee_email: row.invitee_email,
      invitee_user_id: row.invitee_user_id || null,
      role: row.role,
      code: row.code,
      status: row.status,
      created_at: row.created_at,
      expires_at: row.expires_at,
      pets: row.pets,
    })),
  };
}

function mapShareLinkRow(row) {
  return {
    id: row.id,
    code: row.code,
    status: row.status || 'pending',
    created_at: row.created_at,
    claimed_at: row.claimed_at,
    expires_at: row.expires_at
      ? (row.expires_at.toISOString?.() || String(row.expires_at))
      : null,
    claimed_by: row.claimed_by,
    claimed_by_name: row.claimed_by_name?.trim() || null,
    access_role: row.access_role || CARER_ROLE,
  };
}

function mapPetAccessRow(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    user_id: row.user_id,
    role: row.role,
    invited_by: row.invited_by || null,
    created_at: row.created_at,
    user: {
      first_name: row.first_name || '',
      last_name: row.last_name || '',
      category: row.category || 'pet_carer',
      bio: row.bio || '',
      photo_url: row.photo_url || '',
    },
  };
}

export async function listShareLinks(pool, userId, petId) {
  if (!(await userCanSharePet(pool, petId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const seesAllLinks = await userIsOwnerOrCoParent(pool, petId, userId);
  const rows = await listShareLinksForPet(pool, petId, {
    createdBy: seesAllLinks ? null : userId,
  });
  return { links: rows.map(mapShareLinkRow) };
}

export async function stopFollowing(pool, userId, petId) {
  const pet = await findPetNameAndOwner(pool, petId);
  if (!pet) {
    return { error: 'Pet not found', status: 404 };
  }

  const deleted = await deleteSharedAccessForUser(pool, petId, userId);
  if (deleted.length === 0) {
    return { error: 'Shared access not found', status: 404 };
  }

  const follower = await findUserDisplayFields(pool, userId);
  const followerName = userDisplayName(follower);

  await createNotification(pool, {
    userId: pet.user_id,
    petId,
    petName: pet.name,
    title: 'Stopped following',
    message: `${followerName} stopped following ${pet.name}.`,
    type: 'general',
  });

  return { message: 'Stopped following pet' };
}

export async function listAccess(pool, userId, petId) {
  if (!(await userCanSharePet(pool, petId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const rows = await listAccessForPet(pool, petId);
  return { access: rows.map(mapPetAccessRow) };
}

export async function changeRole(pool, { userId, petId, targetUserId, nextRole }) {
  if (![CARER_ROLE, CO_PARENT_ROLE].includes(nextRole)) {
    return { error: 'role must be carer or co_parent', status: 400 };
  }
  if (!(await userCanSharePet(pool, petId, userId))) {
    return { error: 'Forbidden', status: 403 };
  }
  const updated = await updateAccessRole(pool, { petId, targetUserId, nextRole });
  if (!updated) {
    return { error: 'Access not found', status: 404 };
  }
  return { user_id: targetUserId, role: updated.role };
}

export async function removeAccess(pool, { actorId, petId, targetUserId }) {
  if (!(await userCanSharePet(pool, petId, actorId))) {
    return { error: 'Forbidden', status: 403 };
  }

  const petName = (await findPetName(pool, petId)) || 'the pet';
  const actor = await findUserDisplayFields(pool, actorId);
  const actorName = userDisplayName(actor);

  const deleted = await deleteAccessForTargetUser(pool, petId, targetUserId);
  if (deleted.length === 0) {
    return { error: 'Access not found', status: 404 };
  }

  await createNotification(pool, {
    userId: targetUserId,
    petId,
    petName,
    title: 'Sharing ended',
    message: `${actorName} stopped sharing ${petName} with you.`,
    type: 'general',
  });

  return { message: 'Access removed' };
}
