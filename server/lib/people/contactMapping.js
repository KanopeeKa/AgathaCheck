/**
 * @param {object} row people_contacts row with optional roles[], private_note
 */
export function contactRowToMap(row) {
  return {
    id: row.id,
    directory_id: row.directory_id,
    kind: row.kind,
    name: row.name,
    phone: row.phone ?? null,
    email: row.email ?? null,
    address: row.address ?? null,
    website: row.website ?? null,
    works_at_contact_id: row.works_at_contact_id ?? null,
    linked_user_id: row.linked_user_id ?? null,
    inactive_at: row.inactive_at ? row.inactive_at.toISOString?.() || String(row.inactive_at) : null,
    legacy_vet_id: row.legacy_vet_id ?? null,
    roles: Array.isArray(row.roles) ? row.roles : [],
    private_note: row.private_note ?? '',
    household_note: row.household_note !== undefined ? row.household_note : undefined,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @param {string} viewerUserId
 */
export async function loadContactForViewer(pool, contactId, viewerUserId) {
  const result = await pool.query(
    `SELECT pc.*,
      pd.household_id AS directory_household_id,
      COALESCE(
        (SELECT array_agg(pcr.role ORDER BY pcr.role)
         FROM people_contact_roles pcr WHERE pcr.contact_id = pc.id),
        ARRAY[]::text[]
      ) AS roles,
      COALESCE(pcpn.note, '') AS private_note
     FROM people_contacts pc
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     LEFT JOIN people_contact_private_notes pcpn
       ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
     WHERE pc.id = $1
       AND (
         pd.owner_user_id = $2
         OR (
           pd.household_id IS NOT NULL
           AND EXISTS (
             SELECT 1 FROM household_members hm
             WHERE hm.household_id = pd.household_id
               AND hm.user_id = $2
               AND (hm.is_organiser = true OR hm.access_tier = 'full_access')
           )
         )
       )`,
    [contactId, viewerUserId],
  );
  return result.rows[0] ?? null;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} directoryId
 * @param {string} viewerUserId
 * @param {boolean} [includeInactive]
 */
export async function listContactsInDirectory(pool, directoryId, viewerUserId, includeInactive = false) {
  const inactiveFilter = includeInactive ? '' : 'AND pc.inactive_at IS NULL';
  const result = await pool.query(
    `SELECT pc.*,
      COALESCE(
        (SELECT array_agg(pcr.role ORDER BY pcr.role)
         FROM people_contact_roles pcr WHERE pcr.contact_id = pc.id),
        ARRAY[]::text[]
      ) AS roles,
      COALESCE(pcpn.note, '') AS private_note
     FROM people_contacts pc
     LEFT JOIN people_contact_private_notes pcpn
       ON pcpn.contact_id = pc.id AND pcpn.user_id = $2
     WHERE pc.directory_id = $1 ${inactiveFilter}
     ORDER BY pc.name`,
    [directoryId, viewerUserId],
  );
  return result.rows;
}
