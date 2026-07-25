/** G0 §11 retention categories for org-local prospects (J4 Phase 1). */
export const PROSPECT_RETENTION_CATEGORIES = new Set([
  'manual_contact',
  'declined_archived',
  'prospect_relationship',
]);

export function defaultRetentionCategoryForProspect({ userId } = {}) {
  if (userId) {
    return 'prospect_relationship';
  }
  return 'manual_contact';
}

export function isValidProspectRetentionCategory(value) {
  return PROSPECT_RETENTION_CATEGORIES.has(value);
}

export function prospectToMap(row) {
  const displayName = (row.display_name || '').trim();
  return {
    id: row.id,
    organization_id: row.organization_id,
    display_name: displayName || row.email || '',
    email: row.email || null,
    phone: row.phone || null,
    notes: row.notes || '',
    user_id: row.user_id || null,
    creation_source: row.creation_source || 'manual_shelter_entry',
    lawful_basis_attested_at: row.lawful_basis_attested_at || null,
    lawful_basis_attested_by: row.lawful_basis_attested_by || null,
    opt_out_at: row.opt_out_at || null,
    retention_category: row.retention_category || 'manual_contact',
    created_by: row.created_by || null,
    created_at: row.created_at || null,
    updated_at: row.updated_at || null,
  };
}

/**
 * Find registered users matching email (case-insensitive) for prospect merge suggestions.
 */
export async function findProspectMergeSuggestionsByEmail(pool, email) {
  if (!email || !email.trim()) return [];

  const { rows } = await pool.query(
    `SELECT u.id AS user_id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            u.email
     FROM users u
     WHERE LOWER(u.email) = LOWER($1)
     ORDER BY u.email
     LIMIT 10`,
    [email.trim()],
  );

  return rows.map((row) => ({
    user_id: row.user_id,
    display_name: (row.display_name || '').trim() || row.email,
    email: row.email,
    is_org_member: false,
  }));
}

/**
 * Merge a manual prospect record into a registered user account.
 */
export async function mergeProspectIntoUser(pool, {
  orgId,
  prospectId,
  targetUserId,
}) {
  const prospectResult = await pool.query(
    `SELECT * FROM prospects
     WHERE id = $1 AND organization_id = $2`,
    [prospectId, orgId],
  );
  if (prospectResult.rows.length === 0) {
    return { error: 'not_found', status: 404 };
  }
  const prospect = prospectResult.rows[0];
  if (prospect.user_id && prospect.user_id !== targetUserId) {
    return { error: 'already_linked_to_different_user', status: 409 };
  }

  const userResult = await pool.query(
    'SELECT id, email, first_name, last_name FROM users WHERE id = $1',
    [targetUserId],
  );
  if (userResult.rows.length === 0) {
    return { error: 'target_user_not_found', status: 404 };
  }

  const mergedFromId = prospect.id;
  const updateResult = await pool.query(
    `UPDATE prospects
     SET user_id = $1,
         retention_category = 'prospect_relationship',
         updated_at = NOW()
     WHERE id = $2 AND organization_id = $3
     RETURNING *`,
    [targetUserId, prospectId, orgId],
  );

  return {
    status: 200,
    row: updateResult.rows[0],
    mergedFromId,
    mergedIntoUserId: targetUserId,
  };
}
