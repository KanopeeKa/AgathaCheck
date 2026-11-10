/**
 * Shared SQL for aggregating people_contact_roles into a text array.
 * Alias `pc` must be people_contacts in the outer query.
 */
export const CONTACT_ROLES_AGG_SQL = `COALESCE(
  (SELECT array_agg(pcr.role ORDER BY pcr.role)
   FROM people_contact_roles pcr WHERE pcr.contact_id = pc.id),
  ARRAY[]::text[]
)`;
