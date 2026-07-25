/**
 * J3 Ph4: fostering_activity_summary read model for Manage Fosters tabs (G0 §4.4).
 */
import {
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
} from './fosterPlacements.js';

export const ACTIVITY_NOT_YET_PLACED = 'not_yet_placed';
export const ACTIVITY_IN_PREPARATION = 'in_preparation';
export const ACTIVITY_ACTIVELY_FOSTERING = 'actively_fostering';
export const ACTIVITY_RECENTLY_ENDED = 'recently_ended';
export const ACTIVITY_INACTIVE = 'inactive';

export const RECENTLY_ENDED_DAYS = 90;

const PREPARATION_STATUSES = [
  SESSION_STATUS_PENDING_ACCEPTANCE,
  SESSION_STATUS_PREPARATION,
  SESSION_STATUS_READY_TO_START,
];

const ACTIVE_STATUSES = [
  SESSION_STATUS_ACTIVE,
  SESSION_STATUS_ADOPTION_IN_PROGRESS,
  SESSION_STATUS_END_PENDING_CONFIRMATION,
];

const TERMINAL_STATUSES = [
  'returned_to_shelter',
  'transferred',
  'cancelled',
  'converted_to_adoption',
  'not_in_foster',
  'adopted',
];

export function deriveActivitySummary({
  preparationCount = 0,
  activeCount = 0,
  recentlyEndedCount = 0,
  hasAnyHistory = false,
}) {
  if (activeCount > 0) return ACTIVITY_ACTIVELY_FOSTERING;
  if (preparationCount > 0) return ACTIVITY_IN_PREPARATION;
  if (recentlyEndedCount > 0) return ACTIVITY_RECENTLY_ENDED;
  if (!hasAnyHistory) return ACTIVITY_NOT_YET_PLACED;
  return ACTIVITY_INACTIVE;
}

export async function loadActivityCountsByFosterUser(pool, orgId) {
  const result = await pool.query(
    `SELECT fp.foster_user_id,
            COUNT(*) FILTER (WHERE fp.status = ANY($2::text[]))::int AS preparation_count,
            COUNT(*) FILTER (WHERE fp.status = ANY($3::text[]))::int AS active_count,
            COUNT(*) FILTER (
              WHERE fp.status = ANY($4::text[])
                AND fp.updated_at >= NOW() - ($5::text || ' days')::interval
            )::int AS recently_ended_count,
            COUNT(*)::int AS total_count
     FROM foster_placements fp
     WHERE fp.organization_id = $1
       AND fp.foster_user_id IS NOT NULL
     GROUP BY fp.foster_user_id`,
    [
      orgId,
      PREPARATION_STATUSES,
      ACTIVE_STATUSES,
      TERMINAL_STATUSES,
      String(RECENTLY_ENDED_DAYS),
    ],
  );

  const counts = new Map();
  for (const row of result.rows) {
    counts.set(row.foster_user_id, {
      preparationCount: parseInt(row.preparation_count, 10) || 0,
      activeCount: parseInt(row.active_count, 10) || 0,
      recentlyEndedCount: parseInt(row.recently_ended_count, 10) || 0,
      hasAnyHistory: (parseInt(row.total_count, 10) || 0) > 0,
    });
  }
  return counts;
}

export function activitySummaryForFoster(counts = {}) {
  return deriveActivitySummary({
    preparationCount: counts.preparationCount || 0,
    activeCount: counts.activeCount || 0,
    recentlyEndedCount: counts.recentlyEndedCount || 0,
    hasAnyHistory: counts.hasAnyHistory || false,
  });
}

export async function loadActivityCountsByParentId(pool, orgId) {
  const result = await pool.query(
    `SELECT COALESCE(fp.shelter_foster_relationship_id, fp.org_foster_parent_id) AS parent_id,
            COUNT(*) FILTER (WHERE fp.status = ANY($2::text[]))::int AS preparation_count,
            COUNT(*) FILTER (WHERE fp.status = ANY($3::text[]))::int AS active_count,
            COUNT(*) FILTER (
              WHERE fp.status = ANY($4::text[])
                AND fp.updated_at >= NOW() - ($5::text || ' days')::interval
            )::int AS recently_ended_count,
            COUNT(*)::int AS total_count
     FROM foster_placements fp
     WHERE fp.organization_id = $1
       AND COALESCE(fp.shelter_foster_relationship_id, fp.org_foster_parent_id) IS NOT NULL
     GROUP BY COALESCE(fp.shelter_foster_relationship_id, fp.org_foster_parent_id)`,
    [
      orgId,
      PREPARATION_STATUSES,
      ACTIVE_STATUSES,
      TERMINAL_STATUSES,
      String(RECENTLY_ENDED_DAYS),
    ],
  );

  const counts = new Map();
  for (const row of result.rows) {
    counts.set(row.parent_id, {
      preparationCount: parseInt(row.preparation_count, 10) || 0,
      activeCount: parseInt(row.active_count, 10) || 0,
      recentlyEndedCount: parseInt(row.recently_ended_count, 10) || 0,
      hasAnyHistory: (parseInt(row.total_count, 10) || 0) > 0,
    });
  }
  return counts;
}
