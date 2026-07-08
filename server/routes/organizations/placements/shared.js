import { placementToMap } from '../../../lib/fosterPlacements.js';

/** Shared SELECT fragment for placement detail rows (pet + org + foster user). */
export const PLACEMENT_DETAIL_SELECT = `
  SELECT fp.*,
         p.name AS pet_name,
         p.species AS pet_species,
         o.name AS organization_name,
         TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
         u.email AS foster_email
  FROM foster_placements fp
  JOIN pets p ON p.id = fp.pet_id
  JOIN organizations o ON o.id = fp.organization_id
  JOIN users u ON u.id = fp.foster_user_id`;

export async function queryPlacementRows(pool, sqlSuffix, params) {
  const result = await pool.query(`${PLACEMENT_DETAIL_SELECT} ${sqlSuffix}`, params);
  return result.rows.map((row) => placementToMap(row));
}

export async function queryPlacementDetailById(pool, placementId) {
  const rows = await queryPlacementRows(pool, 'WHERE fp.id = $1', [placementId]);
  return rows[0] ?? null;
}
