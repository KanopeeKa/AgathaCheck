import {
  listAccessForPetIds,
  listPendingInvitesForPetIds,
} from '../../db/sharing/shareAccessQueries.js';
import { listPendingInvitesForPet } from '../../db/sharing/shareInviteQueries.js';
import { userCanSharePet } from '../../lib/petAccess.js';

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
