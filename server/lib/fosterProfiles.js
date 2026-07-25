import { v4 as uuidv4 } from 'uuid';

/**
 * J1 Phase 3: foster_profiles table, foster_profile_id FK, backfill existing rows.
 */
export async function migrateFosterProfiles(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS foster_profiles (
      id UUID PRIMARY KEY,
      user_id UUID UNIQUE REFERENCES users(id) ON DELETE SET NULL,
      display_name VARCHAR(255) NOT NULL DEFAULT '',
      email VARCHAR(255),
      phone VARCHAR(50),
      foster_address TEXT DEFAULT '',
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE INDEX IF NOT EXISTS idx_foster_profiles_email_lower
      ON foster_profiles (LOWER(email))
      WHERE email IS NOT NULL
  `);

  await client.query(`
    ALTER TABLE org_foster_parents
      ADD COLUMN IF NOT EXISTS foster_profile_id UUID REFERENCES foster_profiles(id) ON DELETE SET NULL
  `);

  const { rows: parents } = await client.query(
    `SELECT id, user_id, display_name, email, phone, foster_address, foster_profile_id
     FROM org_foster_parents
     WHERE foster_profile_id IS NULL`,
  );

  for (const parent of parents) {
    let profileId = null;

    if (parent.user_id) {
      const existing = await client.query(
        'SELECT id FROM foster_profiles WHERE user_id = $1',
        [parent.user_id],
      );
      if (existing.rows.length > 0) {
        profileId = existing.rows[0].id;
      }
    }

    if (!profileId && parent.email) {
      const byEmail = await client.query(
        `SELECT id FROM foster_profiles
         WHERE user_id IS NULL AND LOWER(email) = LOWER($1)
         LIMIT 1`,
        [parent.email],
      );
      if (byEmail.rows.length > 0) {
        profileId = byEmail.rows[0].id;
      }
    }

    if (!profileId) {
      profileId = uuidv4();
      await client.query(
        `INSERT INTO foster_profiles (
           id, user_id, display_name, email, phone, foster_address
         ) VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          profileId,
          parent.user_id || null,
          parent.display_name || '',
          parent.email || null,
          parent.phone || null,
          parent.foster_address || '',
        ],
      );
    }

    await client.query(
      `UPDATE org_foster_parents
       SET foster_profile_id = $1, updated_at = NOW()
       WHERE id = $2`,
      [profileId, parent.id],
    );
  }
}

/**
 * Ensure a foster profile exists for a new manual org_foster_parent row.
 */
export async function createFosterProfileForManualParent(client, {
  userId = null,
  displayName,
  email,
  phone,
  fosterAddress,
}) {
  const profileId = uuidv4();
  await client.query(
    `INSERT INTO foster_profiles (
       id, user_id, display_name, email, phone, foster_address
     ) VALUES ($1, $2, $3, $4, $5, $6)`,
    [profileId, userId, displayName, email, phone, fosterAddress || ''],
  );
  return profileId;
}

/**
 * Find registered users matching email (case-insensitive) for merge suggestions.
 */
export async function findMergeSuggestionsByEmail(pool, email, orgId) {
  if (!email || !email.trim()) return [];

  const { rows } = await pool.query(
    `SELECT u.id AS user_id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            u.email,
            fp.id AS foster_profile_id
     FROM users u
     LEFT JOIN foster_profiles fp ON fp.user_id = u.id
     WHERE LOWER(u.email) = LOWER($1)
     ORDER BY u.email
     LIMIT 10`,
    [email.trim()],
  );

  return rows.map((row) => ({
    user_id: row.user_id,
    display_name: (row.display_name || '').trim() || row.email,
    email: row.email,
    foster_profile_id: row.foster_profile_id,
    is_org_member: false,
  }));
}

/**
 * Merge a manual shelter–foster relationship into a registered user's profile.
 */
export async function mergeManualFosterIntoUser(pool, {
  orgId,
  fosterParentId,
  targetUserId,
  actorUserId,
}) {
  const parentResult = await pool.query(
    `SELECT * FROM org_foster_parents
     WHERE id = $1 AND organization_id = $2`,
    [fosterParentId, orgId],
  );
  if (parentResult.rows.length === 0) {
    return { error: 'not_found', status: 404 };
  }
  const parent = parentResult.rows[0];
  if (parent.user_id && parent.user_id !== targetUserId) {
    return { error: 'already_linked_to_different_user', status: 409 };
  }

  const userResult = await pool.query(
    'SELECT id, email, first_name, last_name FROM users WHERE id = $1',
    [targetUserId],
  );
  if (userResult.rows.length === 0) {
    return { error: 'target_user_not_found', status: 404 };
  }
  const targetUser = userResult.rows[0];

  const mergedFromProfileId = parent.foster_profile_id;

  let survivorProfileId = null;
  const existingProfile = await pool.query(
    'SELECT id FROM foster_profiles WHERE user_id = $1',
    [targetUserId],
  );
  if (existingProfile.rows.length > 0) {
    survivorProfileId = existingProfile.rows[0].id;
  } else {
    survivorProfileId = uuidv4();
    const displayName = `${targetUser.first_name || ''} ${targetUser.last_name || ''}`.trim()
      || parent.display_name
      || targetUser.email;
    await pool.query(
      `INSERT INTO foster_profiles (
         id, user_id, display_name, email, phone, foster_address
       ) VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        survivorProfileId,
        targetUserId,
        displayName,
        targetUser.email || parent.email,
        parent.phone,
        parent.foster_address || '',
      ],
    );
  }

  const updateResult = await pool.query(
    `UPDATE org_foster_parents
     SET user_id = $1,
         foster_profile_id = $2,
         updated_at = NOW()
     WHERE id = $3 AND organization_id = $4
     RETURNING *`,
    [targetUserId, survivorProfileId, fosterParentId, orgId],
  );

  if (
    mergedFromProfileId
    && mergedFromProfileId !== survivorProfileId
  ) {
    const refs = await pool.query(
      'SELECT COUNT(*)::int AS count FROM org_foster_parents WHERE foster_profile_id = $1',
      [mergedFromProfileId],
    );
    if (refs.rows[0].count === 0) {
      await pool.query('DELETE FROM foster_profiles WHERE id = $1', [mergedFromProfileId]);
    }
  }

  return {
    status: 200,
    row: updateResult.rows[0],
    survivorProfileId,
    mergedFromProfileId,
    mergedFromRelationshipId: fosterParentId,
  };
}
