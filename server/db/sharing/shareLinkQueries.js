import { CO_PARENT_ROLE, FOSTER_PET_ACCESS_ROLE, PET_ACCESS_ROLES } from '../../lib/petAccess.js';

const PET_ACCESS_ROLES_SQL = PET_ACCESS_ROLES.map((role) => `'${role}'`).join(', ');

export async function loadShareLinkByCode(db, code) {
  const result = await db.query(
    `SELECT sl.*, p.user_id as owner_id
     FROM pet_share_links sl
     JOIN pets p ON p.id = sl.pet_id
     WHERE sl.code = $1`,
    [code],
  );
  return result.rows[0] || null;
}

export async function insertShareLink(db, { id, petId, code, createdBy, expiresAt, accessRole }) {
  await db.query(
    `INSERT INTO pet_share_links (id, pet_id, code, created_by, status, expires_at, access_role)
     VALUES ($1, $2, $3, $4, 'pending', $5, $6)`,
    [id, petId, code, createdBy, expiresAt, accessRole],
  );
}

export async function deleteShareLink(db, linkId, userId) {
  const result = await db.query(
    `DELETE FROM pet_share_links sl
     USING pets p
     WHERE sl.id = $1 AND sl.pet_id = p.id
       AND sl.status IN ('pending', 'active', 'revoked')
       AND (
         p.user_id = $2
         OR EXISTS (
           SELECT 1 FROM pet_access pa
           WHERE pa.pet_id = p.id AND pa.user_id = $2
             AND pa.role = '${CO_PARENT_ROLE}'
             AND COALESCE(pa.hidden, false) = false
         )
         OR (
           sl.created_by = $2
           AND EXISTS (
             SELECT 1 FROM pet_access pa
             INNER JOIN foster_placements fp
               ON fp.pet_id = pa.pet_id AND fp.foster_user_id = pa.user_id
             WHERE pa.pet_id = p.id AND pa.user_id = $2
               AND pa.role = '${FOSTER_PET_ACCESS_ROLE}'
               AND fp.status = 'in_progress'
               AND COALESCE(pa.hidden, false) = false
           )
         )
       )
     RETURNING sl.id, sl.status`,
    [linkId, userId],
  );
  return result.rows;
}

export async function findPetById(db, petId) {
  const result = await db.query('SELECT * FROM pets WHERE id = $1', [petId]);
  return result.rows[0] || null;
}

export async function findOwnerFirstName(db, userId) {
  const result = await db.query(
    'SELECT first_name FROM users WHERE id = $1',
    [userId],
  );
  return result.rows[0] || {};
}

export async function loadShareLinkForAccept(db, code) {
  const result = await db.query(
    `SELECT sl.*, p.user_id as owner_id, p.name as pet_name
     FROM pet_share_links sl
     JOIN pets p ON p.id = sl.pet_id
     WHERE sl.code = $1
     FOR UPDATE OF sl`,
    [code],
  );
  return result.rows[0] || null;
}

export async function findPetAccessRole(db, petId, userId) {
  const result = await db.query(
    'SELECT role FROM pet_access WHERE pet_id = $1 AND user_id = $2',
    [petId, userId],
  );
  return result.rows[0]?.role || null;
}

export async function insertPetAccessFromLink(db, {
  id,
  petId,
  userId,
  role,
  invitedBy,
  shareLinkId,
}) {
  await db.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by, share_link_id)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [id, petId, userId, role, invitedBy, shareLinkId],
  );
}

export async function activateShareLink(db, linkId, userId) {
  await db.query(
    `UPDATE pet_share_links
     SET status = 'active', claimed_by = $1, claimed_at = NOW()
     WHERE id = $2`,
    [userId, linkId],
  );
}

export async function findAccepterUser(db, userId) {
  const result = await db.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [userId],
  );
  return result.rows[0] || {};
}

export async function listHiddenPets(db, userId) {
  const result = await db.query(
    'SELECT pa.*, p.name as pet_name FROM pet_access pa JOIN pets p ON p.id = pa.pet_id WHERE pa.user_id = $1 AND pa.hidden = true',
    [userId],
  );
  return result.rows;
}

export async function findPetAccessForHide(db, petId, userId) {
  const result = await db.query(
    `SELECT role FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL}, '${FOSTER_PET_ACCESS_ROLE}')
     LIMIT 1`,
    [petId, userId],
  );
  return result.rows[0]?.role || null;
}

export async function updatePetAccessHidden(db, { hidden, petId, userId, role }) {
  await db.query(
    'UPDATE pet_access SET hidden = $1 WHERE pet_id = $2 AND user_id = $3 AND role = $4',
    [hidden, petId, userId, role],
  );
}
