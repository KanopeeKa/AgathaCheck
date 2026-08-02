import { DERIVED_STATUS_NEARLY_FINISHED, deriveSessionStatus } from '../../../lib/deriveSessionStatus.js';
import { SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT } from '../../../lib/fosterPlacements.js';

export function buildPlacementListFilters(orgId, query = {}) {
  const conditions = ['fp.organization_id = $1'];
  const params = [orgId];
  let paramIdx = 2;

  const petName = String(query.pet_name ?? '').trim();
  if (petName) {
    conditions.push(`p.name ILIKE $${paramIdx}`);
    params.push(`%${petName}%`);
    paramIdx += 1;
  }

  const fosterName = String(query.foster_name ?? '').trim();
  if (fosterName) {
    conditions.push(
      `TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) ILIKE $${paramIdx}`,
    );
    params.push(`%${fosterName}%`);
    paramIdx += 1;
  }

  const status = query.status;
  if (status) {
    const statuses = Array.isArray(status) ? status : String(status).split(',').map((s) => s.trim()).filter(Boolean);
    if (statuses.length) {
      conditions.push(`fp.status = ANY($${paramIdx}::text[])`);
      params.push(statuses);
      paramIdx += 1;
    }
  }

  for (const [queryKey, column] of [
    ['start_date_from', 'fp.start_date >='],
    ['start_date_to', 'fp.start_date <='],
    ['end_date_from', 'fp.end_date >='],
    ['end_date_to', 'fp.end_date <='],
  ]) {
    const value = String(query[queryKey] ?? '').trim();
    if (value) {
      conditions.push(`${column} $${paramIdx}`);
      params.push(value);
      paramIdx += 1;
    }
  }

  const inViewToAdopt = query.in_view_to_adopt;
  if (inViewToAdopt === 'true' || inViewToAdopt === true) {
    conditions.push(`fp.session_type = '${SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT}'`);
  } else if (inViewToAdopt === 'false' || inViewToAdopt === false) {
    conditions.push(`COALESCE(fp.session_type, '') != '${SESSION_TYPE_FOSTER_IN_VIEW_TO_ADOPT}'`);
  }

  return {
    sqlSuffix: `WHERE ${conditions.join(' AND ')} ORDER BY fp.created_at DESC`,
    params,
    derivedStatus: String(query.derived_status ?? '').trim() || null,
  };
}

export function applyDerivedStatusFilter(rows, derivedStatus, now = new Date()) {
  if (!derivedStatus) return rows;
  return rows.filter((row) => deriveSessionStatus(row, now).derived_status === derivedStatus);
}

export function enrichPlacementRow(row, now = new Date()) {
  const derived = deriveSessionStatus(row, now);
  return {
    ...row,
    derived_status: derived.derived_status,
    nearly_finished: derived.nearly_finished,
    in_view_to_adopt: derived.in_view_to_adopt,
  };
}

export { DERIVED_STATUS_NEARLY_FINISHED };
