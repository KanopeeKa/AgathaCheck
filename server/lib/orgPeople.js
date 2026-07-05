/**
 * Organisation people directory — unified members + external fosters.
 */
import {
  FOSTER_ACTIVE_STATUSES,
  OPEN_PLACEMENT_STATUSES,
  placementToMap,
} from './fosterPlacements.js';
import { normaliseRole } from './orgRoles.js';

const FOSTER_ACTIVE_SQL = FOSTER_ACTIVE_STATUSES.map((s) => `'${s}'`).join(', ');
const OPEN_SQL = OPEN_PLACEMENT_STATUSES.map((s) => `'${s}'`).join(', ');

export function personCategoryRank(role, kind) {
  if (kind === 'external') return 4;
  const r = normaliseRole(role || '');
  if (r === 'super_admin' || r === 'pending_super_admin') return 1;
  if (r === 'admin' || r === 'pending_admin') return 2;
  return 3;
}

export function personRef(kind, id) {
  return `${kind}:${id}`;
}

export function parsePersonRef(ref) {
  const idx = ref.indexOf(':');
  if (idx <= 0) return null;
  return { kind: ref.slice(0, idx), id: ref.slice(idx + 1) };
}

function memberActiveCountSql(aliasUserId, aliasOrgId) {
  return `(
    SELECT COUNT(DISTINCT fpl.pet_id)::int
    FROM foster_placements fpl
    WHERE fpl.organization_id = ${aliasOrgId}
      AND fpl.foster_user_id = ${aliasUserId}
      AND fpl.status IN (${FOSTER_ACTIVE_SQL})
  )`;
}

function externalActiveCountSql(aliasFpId, aliasOrgId) {
  return `(
    SELECT COUNT(DISTINCT fpl.pet_id)::int
    FROM foster_placements fpl
    WHERE fpl.organization_id = ${aliasOrgId}
      AND fpl.org_foster_parent_id = ${aliasFpId}
      AND fpl.status IN (${FOSTER_ACTIVE_SQL})
  )`;
}

export function personSummaryToMap(row) {
  return {
    id: personRef(row.kind, row.record_id),
    kind: row.kind,
    record_id: row.record_id,
    user_id: row.user_id || null,
    display_name: (row.display_name || '').trim() || row.email || '',
    email: row.email || null,
    role: row.role ? normaliseRole(row.role) : null,
    photo_url: row.photo_url || null,
    is_pending: !!row.is_pending,
    active_foster_count: parseInt(row.active_foster_count, 10) || 0,
    category_rank: row.category_rank,
  };
}

export function personDetailToMap(row, extras = {}) {
  return {
    ...personSummaryToMap(row),
    foster_phone: row.foster_phone || '',
    foster_address: row.foster_address || '',
    admin_notes: row.admin_notes || '',
    current_placements: extras.current_placements || [],
    past_placements: extras.past_placements || [],
  };
}

export async function listOrgPeople(pool, orgId) {
  const memberResult = await pool.query(
    `SELECT 'member' AS kind,
            ou.id AS record_id,
            u.id AS user_id,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            u.email,
            u.photo_url,
            ou.role,
            (ou.role LIKE 'pending_%') AS is_pending,
            ${memberActiveCountSql('u.id', 'ou.organization_id')} AS active_foster_count
     FROM organization_users ou
     JOIN users u ON u.id = ou.user_id
     WHERE ou.organization_id = $1
     ORDER BY display_name, u.email`,
    [orgId],
  );

  const externalResult = await pool.query(
    `SELECT 'external' AS kind,
            fp.id AS record_id,
            fp.user_id,
            fp.display_name,
            fp.email,
            NULL::text AS photo_url,
            NULL::varchar AS role,
            false AS is_pending,
            ${externalActiveCountSql('fp.id', 'fp.organization_id')} AS active_foster_count
     FROM org_foster_parents fp
     WHERE fp.organization_id = $1
     ORDER BY fp.display_name, fp.email`,
    [orgId],
  );

  const combined = [
    ...memberResult.rows,
    ...externalResult.rows,
  ].map((row) => ({
    ...row,
    category_rank: personCategoryRank(row.role, row.kind),
  }));

  combined.sort((a, b) => {
    if (a.category_rank !== b.category_rank) {
      return a.category_rank - b.category_rank;
    }
    const countDiff = (b.active_foster_count || 0) - (a.active_foster_count || 0);
    if (countDiff !== 0) return countDiff;
    const nameA = (a.display_name || a.email || '').toLowerCase();
    const nameB = (b.display_name || b.email || '').toLowerCase();
    return nameA.localeCompare(nameB, undefined, { sensitivity: 'base' });
  });

  return combined.map(personSummaryToMap);
}

export function computePlacementOutcome(placement, petPassedAway, fosteredElsewhere) {
  if (petPassedAway) return 'passed_away';
  if (placement.status === 'adopted') return 'adopted';
  if (fosteredElsewhere) return 'in_foster_elsewhere';
  if (placement.status === 'not_in_foster') return 'not_in_foster';
  return 'not_in_foster';
}

async function loadPersonPlacements(pool, orgId, kind, recordId, userId, externalId) {
  let placementFilter;
  let params;
  if (kind === 'member') {
    placementFilter = 'fpl.foster_user_id = $2';
    params = [orgId, userId];
  } else {
    placementFilter = 'fpl.org_foster_parent_id = $2';
    params = [orgId, externalId];
  }

  const result = await pool.query(
    `SELECT fp.*,
            p.name AS pet_name,
            p.species AS pet_species,
            p.passed_away AS pet_passed_away,
            o.name AS organization_name,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS foster_name,
            u.email AS foster_email
     FROM foster_placements fp
     JOIN pets p ON p.id = fp.pet_id
     JOIN organizations o ON o.id = fp.organization_id
     LEFT JOIN users u ON u.id = fp.foster_user_id
     WHERE fp.organization_id = $1
       AND ${placementFilter}
     ORDER BY fp.start_date DESC NULLS LAST, fp.created_at DESC`,
    params,
  );

  const openByPet = await pool.query(
    `SELECT DISTINCT ON (pet_id) pet_id, foster_user_id, org_foster_parent_id, status
     FROM foster_placements
     WHERE organization_id = $1
       AND status IN (${OPEN_SQL})
     ORDER BY pet_id, created_at DESC`,
    [orgId],
  );
  const openMap = new Map(openByPet.rows.map((r) => [r.pet_id, r]));

  const current = [];
  const past = [];

  for (const row of result.rows) {
    const open = openMap.get(row.pet_id);
    let fosteredElsewhere = false;
    if (open && row.status !== open.status) {
      if (kind === 'member') {
        fosteredElsewhere = open.foster_user_id !== userId;
      } else {
        fosteredElsewhere = open.org_foster_parent_id !== externalId;
      }
    } else if (!OPEN_PLACEMENT_STATUSES.includes(row.status)) {
      const currentOpen = openMap.get(row.pet_id);
      if (currentOpen) {
        if (kind === 'member') {
          fosteredElsewhere = currentOpen.foster_user_id !== userId;
        } else {
          fosteredElsewhere = currentOpen.org_foster_parent_id !== externalId;
        }
      }
    }

    const base = placementToMap(row, {
      pet_name: row.pet_name,
      pet_species: row.pet_species,
      organization_name: row.organization_name,
      foster_name: row.foster_name,
      foster_email: row.foster_email,
    });

    if (OPEN_PLACEMENT_STATUSES.includes(row.status)) {
      current.push(base);
    } else {
      past.push({
        ...base,
        outcome: computePlacementOutcome(
          row,
          row.pet_passed_away === true,
          fosteredElsewhere,
        ),
      });
    }
  }

  return { current_placements: current, past_placements: past };
}

export async function getOrgPersonDetail(pool, orgId, kind, recordId) {
  let row;
  if (kind === 'member') {
    const result = await pool.query(
      `SELECT 'member' AS kind,
              ou.id AS record_id,
              u.id AS user_id,
              TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
              u.email,
              u.photo_url,
              ou.role,
              (ou.role LIKE 'pending_%') AS is_pending,
              COALESCE(ou.foster_phone, '') AS foster_phone,
              COALESCE(ou.foster_address, '') AS foster_address,
              COALESCE(ou.admin_notes, '') AS admin_notes,
              ${memberActiveCountSql('u.id', 'ou.organization_id')} AS active_foster_count
       FROM organization_users ou
       JOIN users u ON u.id = ou.user_id
       WHERE ou.organization_id = $1 AND ou.id = $2`,
      [orgId, recordId],
    );
    row = result.rows[0];
    if (!row) return null;
    const placements = await loadPersonPlacements(
      pool,
      orgId,
      'member',
      recordId,
      row.user_id,
      null,
    );
    return personDetailToMap(row, placements);
  }

  const result = await pool.query(
    `SELECT 'external' AS kind,
            fp.id AS record_id,
            fp.user_id,
            fp.display_name,
            fp.email,
            NULL::text AS photo_url,
            NULL::varchar AS role,
            false AS is_pending,
            COALESCE(fp.phone, '') AS foster_phone,
            COALESCE(fp.foster_address, '') AS foster_address,
            COALESCE(fp.notes, '') AS admin_notes,
            ${externalActiveCountSql('fp.id', 'fp.organization_id')} AS active_foster_count
     FROM org_foster_parents fp
     WHERE fp.organization_id = $1 AND fp.id = $2`,
    [orgId, recordId],
  );
  row = result.rows[0];
  if (!row) return null;
  const placements = await loadPersonPlacements(
    pool,
    orgId,
    'external',
    recordId,
    null,
    recordId,
  );
  return personDetailToMap(row, placements);
}

export async function updateOrgPersonContact(pool, orgId, kind, recordId, data) {
  const fosterPhone = (data.foster_phone ?? data.fosterPhone ?? '').trim();
  const fosterAddress = (data.foster_address ?? data.fosterAddress ?? '').trim();
  const adminNotes = (data.admin_notes ?? data.adminNotes ?? '').trim();

  if (kind === 'member') {
    const result = await pool.query(
      `UPDATE organization_users
       SET foster_phone = $1,
           foster_address = $2,
           admin_notes = $3,
           updated_at = NOW()
       WHERE organization_id = $4 AND id = $5
       RETURNING id`,
      [fosterPhone, fosterAddress, adminNotes, orgId, recordId],
    );
    return result.rows.length > 0;
  }

  const displayName = (data.display_name ?? data.displayName ?? '').trim();
  const email = (data.email ?? '').trim() || null;
  if (!displayName) {
    const err = new Error('Display name is required');
    err.statusCode = 400;
    throw err;
  }

  const result = await pool.query(
    `UPDATE org_foster_parents
     SET display_name = $1,
         email = $2,
         phone = $3,
         foster_address = $4,
         notes = $5,
         updated_at = NOW()
     WHERE organization_id = $6 AND id = $7
     RETURNING id`,
    [displayName, email, fosterPhone, fosterAddress, adminNotes, orgId, recordId],
  );
  return result.rows.length > 0;
}

export async function linkExternalFostersByEmail(pool, userId, email) {
  if (!email) return;
  await pool.query(
    `UPDATE org_foster_parents
     SET user_id = $1, updated_at = NOW()
     WHERE LOWER(email) = LOWER($2) AND user_id IS NULL`,
    [userId, email.trim()],
  );
}

export async function listFosterContactsForUser(pool, userId) {
  const userResult = await pool.query(
    'SELECT email FROM users WHERE id = $1',
    [userId],
  );
  const email = userResult.rows[0]?.email;
  if (!email) return [];

  const memberRows = await pool.query(
    `SELECT 'member' AS kind,
            ou.id AS record_id,
            ou.organization_id,
            o.name AS organization_name,
            TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')) AS display_name,
            u.email,
            ou.role,
            COALESCE(ou.foster_phone, '') AS foster_phone,
            COALESCE(ou.foster_address, '') AS foster_address,
            COALESCE(ou.admin_notes, '') AS admin_notes
     FROM organization_users ou
     JOIN users u ON u.id = ou.user_id
     JOIN organizations o ON o.id = ou.organization_id
     WHERE ou.user_id = $1`,
    [userId],
  );

  const externalRows = await pool.query(
    `SELECT 'external' AS kind,
            fp.id AS record_id,
            fp.organization_id,
            o.name AS organization_name,
            fp.display_name,
            fp.email,
            NULL::varchar AS role,
            COALESCE(fp.phone, '') AS foster_phone,
            COALESCE(fp.foster_address, '') AS foster_address,
            COALESCE(fp.notes, '') AS admin_notes
     FROM org_foster_parents fp
     JOIN organizations o ON o.id = fp.organization_id
     WHERE fp.user_id = $1 OR LOWER(fp.email) = LOWER($2)`,
    [userId, email],
  );

  return [...memberRows.rows, ...externalRows.rows].map((row) => ({
    kind: row.kind,
    record_id: row.record_id,
    organization_id: row.organization_id,
    organization_name: row.organization_name,
    display_name: row.display_name,
    email: row.email,
    role: row.role ? normaliseRole(row.role) : null,
    foster_phone: row.foster_phone || '',
    foster_address: row.foster_address || '',
    admin_notes: row.admin_notes || '',
  }));
}
