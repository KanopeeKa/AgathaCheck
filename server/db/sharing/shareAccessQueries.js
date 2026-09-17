const PET_ACCESS_ROLES_SQL = "'carer', 'co_parent'";

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
