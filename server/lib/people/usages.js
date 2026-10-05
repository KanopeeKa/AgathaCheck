/**
 * Active references to a contact that block hard delete (I7).
 * History snapshots on closed occurrences are not usages.
 *
 * @typedef {{ kind: string, id: string, label: string, pet_id?: string, active?: boolean }} ContactUsage
 */

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} contactId
 * @returns {Promise<ContactUsage[]>}
 */
export async function listUsages(pool, contactId) {
  if (!contactId) return [];

  const usages = [];

  const relationships = await pool.query(
    `SELECT pcr.id, pcr.pet_id, pcr.relationship_kind
     FROM pet_contact_relationships pcr
     WHERE pcr.contact_id = $1 AND pcr.active = true`,
    [contactId],
  );
  for (const row of relationships.rows) {
    usages.push({
      kind: 'pet_relationship',
      id: row.id,
      label: row.relationship_kind,
      pet_id: row.pet_id,
      active: true,
    });
  }

  const absenceCarers = await pool.query(
    `SELECT pap.planned_absence_id AS id, pap.pet_id, pa.starts_on::text, pa.ends_on::text
     FROM planned_absence_pets pap
     INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
     WHERE pap.contact_id = $1
       AND pa.status = 'active'
       AND pa.cancelled_at IS NULL
       AND pa.ends_on >= CURRENT_DATE`,
    [contactId],
  );
  for (const row of absenceCarers.rows) {
    usages.push({
      kind: 'absence_carer',
      id: row.id,
      label: `${row.starts_on} – ${row.ends_on}`,
      pet_id: row.pet_id,
      active: true,
    });
  }

  const careProviders = await pool.query(
    `SELECT he.id, he.pet_id, he.name
     FROM health_entries he
     WHERE he.provider_contact_id = $1`,
    [contactId],
  );
  for (const row of careProviders.rows) {
    usages.push({
      kind: 'care_item_provider',
      id: row.id,
      label: row.name || 'Care item',
      pet_id: row.pet_id,
      active: true,
    });
  }

  const invites = await pool.query(
    `SELECT i.id,
            (SELECT ip.pet_id FROM planned_absence_carer_invite_pets ip
             WHERE ip.invite_id = i.id LIMIT 1) AS pet_id
     FROM planned_absence_carer_invites i
     WHERE i.contact_id = $1 AND i.status = 'pending'`,
    [contactId],
  );
  for (const row of invites.rows) {
    usages.push({
      kind: 'carer_invite',
      id: row.id,
      label: 'Pending carer invite',
      ...(row.pet_id ? { pet_id: row.pet_id } : {}),
      active: true,
    });
  }

  const worksAt = await pool.query(
    `SELECT pc.id, pc.name
     FROM people_contacts pc
     WHERE pc.works_at_contact_id = $1`,
    [contactId],
  );
  for (const row of worksAt.rows) {
    usages.push({
      kind: 'works_at',
      id: row.id,
      label: row.name,
      active: true,
    });
  }

  return usages;
}
