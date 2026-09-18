import { PET_ACCESS_ROLES } from '../../lib/petAccess.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

export async function listShareLinksForPet(db, petId, { createdBy } = {}) {
  const params = [petId];
  let createdByFilter = '';
  if (createdBy) {
    createdByFilter = ' AND sl.created_by = $2';
    params.push(createdBy);
  }
  const result = await db.query(
    `SELECT sl.id, sl.code, sl.status, sl.created_at, sl.claimed_at,
            sl.claimed_by, sl.expires_at, sl.access_role,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) as claimed_by_name
     FROM pet_share_links sl
     LEFT JOIN users u ON u.id = sl.claimed_by
     WHERE sl.pet_id = $1${createdByFilter}
     ORDER BY sl.created_at DESC`,
    params,
  );
  return result.rows;
}

export async function findPetNameAndOwner(db, petId) {
  const result = await db.query('SELECT name, user_id FROM pets WHERE id = $1', [petId]);
  return result.rows[0] || null;
}

export async function deleteSharedAccessForUser(db, petId, userId) {
  const result = await db.query(
    `DELETE FROM pet_access
     WHERE pet_id = $1 AND user_id = $2 AND role IN (${PET_ACCESS_ROLES_SQL})
     RETURNING id`,
    [petId, userId],
  );
  return result.rows;
}

export async function listAccessForPet(db, petId) {
  const result = await db.query(
    `SELECT pa.*,
            u.first_name, u.last_name, u.category, u.bio, u.photo_url
     FROM pet_access pa
     JOIN users u ON u.id = pa.user_id
     WHERE pa.pet_id = $1 AND pa.role IN (${PET_ACCESS_ROLES_SQL})
     ORDER BY pa.created_at`,
    [petId],
  );
  return result.rows;
}

export async function updateAccessRole(db, { petId, targetUserId, nextRole }) {
  const result = await db.query(
    `UPDATE pet_access
     SET role = $1, updated_at = NOW()
     WHERE pet_id = $2 AND user_id = $3 AND role IN (${PET_ACCESS_ROLES_SQL})
     RETURNING id, role`,
    [nextRole, petId, targetUserId],
  );
  return result.rows[0] || null;
}

export async function deleteAccessForTargetUser(db, petId, targetUserId) {
  const result = await db.query(
    `DELETE FROM pet_access
     WHERE pet_id = $1 AND user_id = $2 AND role IN (${PET_ACCESS_ROLES_SQL})
     RETURNING id`,
    [petId, targetUserId],
  );
  return result.rows;
}

export async function findPetName(db, petId) {
  const result = await db.query('SELECT name FROM pets WHERE id = $1', [petId]);
  return result.rows[0]?.name || null;
}

export async function findUserDisplayFields(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return result.rows[0] || {};
}

export async function listAccessForPetIds(db, petIds) {
  if (!petIds.length) return [];
  const result = await db.query(
    `SELECT pa.id, pa.pet_id, pa.user_id, pa.role, pa.invited_by, pa.created_at,
            u.first_name, u.last_name, u.email, u.category, u.bio, u.photo_url
     FROM pet_access pa
     JOIN users u ON u.id = pa.user_id
     WHERE pa.pet_id = ANY($1::uuid[])
       AND pa.role IN (${PET_ACCESS_ROLES_SQL})
     ORDER BY pa.pet_id, pa.created_at`,
    [petIds],
  );
  return result.rows;
}

export async function listPendingInvitesForPetIds(db, petIds) {
  if (!petIds.length) return [];
  const result = await db.query(
    `SELECT psi.id, psi.inviter_user_id, psi.invitee_email, psi.invitee_user_id,
            psi.role, psi.code, psi.status, psi.created_at, psi.expires_at,
            psip.pet_id
     FROM pet_share_invites psi
     INNER JOIN pet_share_invite_pets psip ON psip.invite_id = psi.id
     WHERE psip.pet_id = ANY($1::uuid[])
       AND psi.status = 'pending'
       AND psi.expires_at > NOW()
     ORDER BY psip.pet_id, psi.created_at DESC`,
    [petIds],
  );
  return result.rows;
}
