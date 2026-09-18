const PET_ACCESS_ROLES_SQL = "'carer', 'co_parent'";

export async function findUserByEmail(db, email) {
  const result = await db.query(
    'SELECT id, email, first_name, last_name FROM users WHERE LOWER(email) = LOWER($1) LIMIT 1',
    [email],
  );
  return result.rows[0] || null;
}

export async function findInviterEmail(db, userId) {
  const result = await db.query(
    'SELECT email FROM users WHERE id = $1 LIMIT 1',
    [userId],
  );
  return result.rows[0]?.email || null;
}

export async function findPendingInviteForPetAndEmail(db, petId, email) {
  const result = await db.query(
    `SELECT psi.id
     FROM pet_share_invites psi
     INNER JOIN pet_share_invite_pets psip ON psip.invite_id = psi.id
     WHERE psip.pet_id = $1
       AND LOWER(psi.invitee_email) = LOWER($2)
       AND psi.status = 'pending'
       AND psi.expires_at > NOW()
     LIMIT 1`,
    [petId, email],
  );
  return result.rows[0] || null;
}

export async function findExistingAccessForEmail(db, petId, email, userId = null) {
  const result = await db.query(
    `SELECT pa.id
     FROM pet_access pa
     INNER JOIN users u ON u.id = pa.user_id
     WHERE pa.pet_id = $1
       AND pa.role IN (${PET_ACCESS_ROLES_SQL})
       AND COALESCE(pa.hidden, false) = false
       AND (LOWER(u.email) = LOWER($2) OR ($3::uuid IS NOT NULL AND pa.user_id = $3::uuid))
     LIMIT 1`,
    [petId, email, userId],
  );
  return result.rows[0] || null;
}

export async function insertInvite(db, {
  id,
  inviterUserId,
  inviteeEmail,
  inviteeUserId,
  role,
  code,
  expiresAt,
}) {
  await db.query(
    `INSERT INTO pet_share_invites (
       id, inviter_user_id, invitee_email, invitee_user_id, role, code, status, expires_at
     ) VALUES ($1, $2, LOWER($3), $4, $5, $6, 'pending', $7)`,
    [id, inviterUserId, inviteeEmail, inviteeUserId, role, code, expiresAt],
  );
}

export async function insertInvitePets(db, inviteId, petIds) {
  for (const petId of petIds) {
    await db.query(
      'INSERT INTO pet_share_invite_pets (invite_id, pet_id) VALUES ($1, $2)',
      [inviteId, petId],
    );
  }
}

async function loadInvitePets(db, inviteId) {
  const result = await db.query(
    `SELECT psip.pet_id, p.name AS pet_name
     FROM pet_share_invite_pets psip
     LEFT JOIN pets p ON p.id = psip.pet_id
     WHERE psip.invite_id = $1
     ORDER BY p.name NULLS LAST, psip.pet_id`,
    [inviteId],
  );
  return result.rows.map((row) => ({
    pet_id: row.pet_id,
    pet_name: row.pet_name,
  }));
}

async function loadInviterDisplayName(db, inviterUserId) {
  const result = await db.query(
    'SELECT first_name, last_name FROM users WHERE id = $1',
    [inviterUserId],
  );
  const row = result.rows[0] || {};
  const full = `${row.first_name || ''} ${row.last_name || ''}`.trim();
  return full || 'Someone';
}

export async function findInviteById(db, inviteId, { forUpdate = false } = {}) {
  const lock = forUpdate ? ' FOR UPDATE' : '';
  const result = await db.query(
    `SELECT psi.*
     FROM pet_share_invites psi
     WHERE psi.id = $1${lock}`,
    [inviteId],
  );
  const row = result.rows[0];
  if (!row) return null;
  const pets = await loadInvitePets(db, row.id);
  return { ...row, pets };
}

export async function findInviteByCode(db, code, { forUpdate = false } = {}) {
  const lock = forUpdate ? ' FOR UPDATE' : '';
  const result = await db.query(
    `SELECT psi.*
     FROM pet_share_invites psi
     WHERE psi.code = $1${lock}`,
    [code],
  );
  const row = result.rows[0];
  if (!row) return null;
  const pets = await loadInvitePets(db, row.id);
  const inviter_name = await loadInviterDisplayName(db, row.inviter_user_id);
  return { ...row, pets, inviter_name };
}

export async function updateInviteStatus(db, inviteId, status) {
  await db.query(
    `UPDATE pet_share_invites
     SET status = $2, responded_at = NOW()
     WHERE id = $1`,
    [inviteId, status],
  );
}

export async function setInviteeUserId(db, inviteId, userId) {
  await db.query(
    'UPDATE pet_share_invites SET invitee_user_id = $2 WHERE id = $1',
    [inviteId, userId],
  );
}

export async function listPendingInvitesForPet(db, petId) {
  const result = await db.query(
    `SELECT psi.id, psi.invitee_email, psi.invitee_user_id, psi.role, psi.code,
            psi.status, psi.created_at, psi.expires_at,
            COALESCE(
              json_agg(
                json_build_object('pet_id', psip.pet_id, 'pet_name', p.name)
                ORDER BY p.name
              ) FILTER (WHERE psip.pet_id IS NOT NULL),
              '[]'
            ) AS pets
     FROM pet_share_invites psi
     INNER JOIN pet_share_invite_pets psip ON psip.invite_id = psi.id
     LEFT JOIN pets p ON p.id = psip.pet_id
     WHERE psip.pet_id = $1
       AND psi.status = 'pending'
       AND psi.expires_at > NOW()
     GROUP BY psi.id
     ORDER BY psi.created_at DESC`,
    [petId],
  );
  return result.rows.map((row) => ({
    ...row,
    pets: Array.isArray(row.pets) ? row.pets : JSON.parse(row.pets || '[]'),
  }));
}

export async function findPetAccessRole(db, petId, userId) {
  const result = await db.query(
    `SELECT role FROM pet_access
     WHERE pet_id = $1 AND user_id = $2
       AND role IN (${PET_ACCESS_ROLES_SQL})
     LIMIT 1`,
    [petId, userId],
  );
  return result.rows[0]?.role || null;
}

export async function insertPetAccess(db, {
  id,
  petId,
  userId,
  role,
  invitedBy,
}) {
  await db.query(
    `INSERT INTO pet_access (id, pet_id, user_id, role, invited_by)
     VALUES ($1, $2, $3, $4, $5)`,
    [id, petId, userId, role, invitedBy],
  );
}

export async function upgradePetAccessRole(db, petId, userId, role) {
  await db.query(
    `UPDATE pet_access
     SET role = $3, updated_at = NOW()
     WHERE pet_id = $1 AND user_id = $2`,
    [petId, userId, role],
  );
}
