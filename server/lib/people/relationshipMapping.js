export function relationshipRowToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    contact_id: row.contact_id,
    relationship_kind: row.relationship_kind,
    is_primary: row.is_primary === true || row.is_primary === 't',
    active: row.active === true || row.active === 't',
    sort_order: row.sort_order != null ? Number(row.sort_order) : 0,
    contact: row.contact_name
      ? {
        id: row.contact_id,
        kind: row.contact_kind,
        name: row.contact_name,
        phone: row.contact_phone ?? null,
        inactive_at: row.contact_inactive_at
          ? row.contact_inactive_at.toISOString?.() || String(row.contact_inactive_at)
          : null,
      }
      : null,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export const RELATIONSHIP_LIST_SQL = `
  SELECT pcr.*,
    pc.kind AS contact_kind,
    pc.name AS contact_name,
    pc.phone AS contact_phone,
    pc.inactive_at AS contact_inactive_at
  FROM pet_contact_relationships pcr
  INNER JOIN people_contacts pc ON pc.id = pcr.contact_id
  WHERE pcr.pet_id = $1
  ORDER BY pcr.relationship_kind, pcr.sort_order, pc.name`;
