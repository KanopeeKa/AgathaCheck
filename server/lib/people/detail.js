import { dateToIsoDate } from '../calendarDate.js';
import { HOUSEHOLD_TIER_LOG } from '../households/constants.js';
import {
  getHouseholdGrantForUser,
  listHouseholdAccessForPet,
} from '../households/index.js';
import { userHasActiveAbsenceGuestAccess } from './absenceGuestGrants.js';
import {
  CARER_ROLE,
  userCanManageProfile,
  getPetAccessRole,
} from '../petAccess.js';
import {
  canViewContact,
  careHandoverScopeForPet,
} from './access.js';
import { contactRowToMap } from './contactMapping.js';
import {
  contactRowToSummary,
  directoryWire,
  isHandoverRelationshipKind,
} from './contactSummary.js';
import { listUsages } from './usages.js';
import { listForPet } from './relationships.js';
import { householdNoteForViewer } from './householdNotes.js';

async function loadContactRow(pool, contactId, viewerUserId) {
  const result = await pool.query(
    `SELECT pc.*,
      pd.owner_user_id,
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
     WHERE pc.id = $1`,
    [contactId, viewerUserId],
  );
  return result.rows[0] ?? null;
}

async function loadWorksAtDetail(pool, worksAtContactId) {
  if (!worksAtContactId) return null;
  const result = await pool.query(
    'SELECT id, name, phone, email, address FROM people_contacts WHERE id = $1',
    [worksAtContactId],
  );
  const row = result.rows[0];
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    phone: row.phone ?? null,
    email: row.email ?? null,
    address: row.address ?? null,
  };
}

async function loadStaffContacts(pool, organisationContactId) {
  const result = await pool.query(
    `SELECT pc.id, pc.name, pc.kind,
      COALESCE(
        (SELECT array_agg(pcr.role ORDER BY pcr.role)
         FROM people_contact_roles pcr WHERE pcr.contact_id = pc.id),
        ARRAY[]::text[]
      ) AS roles
     FROM people_contacts pc
     WHERE pc.works_at_contact_id = $1 AND pc.inactive_at IS NULL
     ORDER BY pc.name`,
    [organisationContactId],
  );
  return result.rows.map((row) => ({
    id: row.id,
    name: row.name,
    kind: row.kind,
    roles: row.roles || [],
  }));
}

async function loadLinkedAccount(pool, linkedUserId) {
  const result = await pool.query(
    `SELECT id, first_name, last_name, email, photo_url
     FROM users WHERE id = $1`,
    [linkedUserId],
  );
  const row = result.rows[0];
  if (!row) return null;
  const displayName = [row.first_name, row.last_name].filter(Boolean).join(' ').trim()
    || row.email
    || 'User';
  return {
    user_id: row.id,
    display_name: displayName,
    photo_url: row.photo_url || null,
  };
}

function usageCounts(usages) {
  const counts = {};
  for (const u of usages) {
    counts[u.kind] = (counts[u.kind] || 0) + 1;
  }
  return counts;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} contactId
 */
export async function contactDetail(pool, userId, contactId) {
  if (!(await canViewContact(pool, contactId, userId))) {
    return null;
  }
  const row = await loadContactRow(pool, contactId, userId);
  if (!row) return null;

  const base = contactRowToMap(row);
  const directory = directoryWire(row.directory_id, row.directory_household_id ?? null);
  const summaryFields = contactRowToSummary(row, { directory });

  const [worksAt, staff, usages, linkedAccount, householdNote] = await Promise.all([
    loadWorksAtDetail(pool, row.works_at_contact_id),
    row.kind === 'organisation' ? loadStaffContacts(pool, contactId) : Promise.resolve([]),
    listUsages(pool, contactId),
    row.linked_user_id ? loadLinkedAccount(pool, row.linked_user_id) : Promise.resolve(null),
    householdNoteForViewer(
      pool,
      contactId,
      row.directory_household_id ?? null,
      userId,
      row.linked_user_id ?? null,
    ),
  ]);

  return {
    ...base,
    directory,
    group: summaryFields.group,
    status: summaryFields.status,
    works_at: worksAt,
    staff,
    usage_counts: usageCounts(usages),
    household_note: householdNote,
    linked_account: linkedAccount,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} contactId
 */
export async function relatedCare(pool, userId, contactId) {
  if (!(await canViewContact(pool, contactId, userId))) {
    return null;
  }

  const [petsResult, careItems, absences, historyCount] = await Promise.all([
    pool.query(
      `SELECT pcr.pet_id, p.name AS pet_name, pcr.relationship_kind
       FROM pet_contact_relationships pcr
       INNER JOIN pets p ON p.id = pcr.pet_id
       WHERE pcr.contact_id = $1 AND pcr.active = true
       ORDER BY p.name`,
      [contactId],
    ),
    pool.query(
      `SELECT he.id, he.name, he.pet_id
       FROM health_entries he
       WHERE he.provider_contact_id = $1
       ORDER BY he.name`,
      [contactId],
    ),
    pool.query(
      `SELECT pa.id AS absence_id, pa.starts_on, pa.ends_on,
              array_agg(DISTINCT pap.pet_id) AS pet_ids
       FROM planned_absence_pets pap
       INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
       WHERE pap.contact_id = $1
       GROUP BY pa.id, pa.starts_on, pa.ends_on
       ORDER BY pa.starts_on DESC`,
      [contactId],
    ),
    pool.query(
      `SELECT COUNT(*)::int AS count
       FROM health_occurrences ho
       INNER JOIN health_entries he ON he.id = ho.health_entry_id
       WHERE ho.provider_contact_id = $1
          OR he.provider_contact_id = $1`,
      [contactId],
    ),
  ]);

  return {
    pets: petsResult.rows.map((r) => ({
      pet_id: r.pet_id,
      pet_name: r.pet_name,
      relationship_kind: r.relationship_kind,
    })),
    care_items: careItems.rows.map((r) => ({
      id: r.id,
      name: r.name,
      pet_id: r.pet_id,
    })),
    absences: absences.rows.map((r) => ({
      absence_id: r.absence_id,
      starts_on: dateToIsoDate(r.starts_on),
      ends_on: dateToIsoDate(r.ends_on),
      pet_ids: r.pet_ids || [],
    })),
    history_count: historyCount.rows[0]?.count ?? 0,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} vetId
 */
export async function contactIdByLegacyVet(pool, userId, vetId) {
  if (!vetId || !userId) return null;
  const result = await pool.query(
    `SELECT pc.id
     FROM people_contacts pc
     INNER JOIN people_directories pd ON pd.id = pc.directory_id
     WHERE pc.legacy_vet_id = $1 AND pd.owner_user_id = $2
     LIMIT 1`,
    [vetId, userId],
  );
  const id = result.rows[0]?.id;
  return id ? { id } : null;
}

async function resolvePetPeopleScope(pool, petId, userId) {
  if (await userCanManageProfile(pool, petId, userId)) {
    return 'full';
  }
  if (await userHasActiveAbsenceGuestAccess(pool, petId, userId)) {
    return 'handover';
  }
  const householdTier = await getHouseholdGrantForUser(pool, petId, userId);
  if (householdTier === HOUSEHOLD_TIER_LOG) {
    return 'handover';
  }
  const role = await getPetAccessRole(pool, petId, userId);
  if (role === CARER_ROLE) {
    return 'handover';
  }
  return null;
}

function mapHouseholdMemberRow(row) {
  const displayName = [row.first_name, row.last_name].filter(Boolean).join(' ').trim()
    || 'Member';
  return {
    user_id: row.user_id,
    display_name: displayName,
    first_name: row.first_name || '',
    tier: row.access_tier,
    is_organiser: row.is_organiser === true,
  };
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {string} petId
 */
export async function petPeople(pool, userId, petId) {
  const scope = await resolvePetPeopleScope(pool, petId, userId);
  if (!scope) return null;

  const petResult = await pool.query(
    'SELECT id, name, user_id FROM pets WHERE id = $1',
    [petId],
  );
  const pet = petResult.rows[0];
  if (!pet) return null;

  const ownerResult = await pool.query(
    'SELECT first_name, last_name, email FROM users WHERE id = $1',
    [pet.user_id],
  );
  const ownerRow = ownerResult.rows[0];
  const ownerDisplay = ownerRow
    ? [ownerRow.first_name, ownerRow.last_name].filter(Boolean).join(' ').trim()
      || ownerRow.email
      || 'Owner'
    : 'Owner';

  let relationships = await listForPet(pool, petId);
  let householdMembers = [];

  if (scope === 'handover') {
    const handover = await careHandoverScopeForPet(pool, userId, petId);
    const allowedContactIds = new Set(handover.contact_ids);
    relationships = relationships.filter(
      (r) => r.active && (
        isHandoverRelationshipKind(r.relationship_kind)
        || allowedContactIds.has(r.contact_id)
      ),
    );
  } else {
    const memberRows = await listHouseholdAccessForPet(pool, petId);
    householdMembers = memberRows.map(mapHouseholdMemberRow);
  }

  return {
    pet_id: pet.id,
    pet_name: pet.name,
    scope,
    owner: {
      user_id: pet.user_id,
      display_name: ownerDisplay,
    },
    household_members: householdMembers,
    relationships,
  };
}
