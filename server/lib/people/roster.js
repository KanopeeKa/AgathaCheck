import { dateToIsoDate, timestampToIso } from '../calendarDate.js';
import { listHouseholdsForUser } from '../households/index.js';
import { contactRowToMap } from './contactMapping.js';
import {
  contactRowToSummary,
  directoryWire,
  nextAbsenceWire,
  petsWireForContact,
  worksAtWire,
} from './contactSummary.js';
import { visibleDirectoryIds } from './access.js';

async function loadContactsForDirectories(pool, directoryIds, viewerUserId, includeInactive) {
  if (directoryIds.length === 0) return [];
  const inactiveFilter = includeInactive ? '' : 'AND pc.inactive_at IS NULL';
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
     WHERE pc.directory_id = ANY($1::uuid[]) ${inactiveFilter}
     ORDER BY pc.name`,
    [directoryIds, viewerUserId],
  );
  return result.rows;
}

async function loadPetsByContactIds(pool, contactIds, viewerUserId) {
  if (contactIds.length === 0) return new Map();
  const result = await pool.query(
    `SELECT pcr.contact_id, pcr.pet_id, pcr.relationship_kind, pcr.is_primary, p.name AS pet_name
     FROM pet_contact_relationships pcr
     INNER JOIN pets p ON p.id = pcr.pet_id
     WHERE pcr.contact_id = ANY($1::uuid[])
       AND pcr.active = true
       AND (
         p.user_id = $2
         OR EXISTS (
           SELECT 1 FROM pet_access pa
           WHERE pa.pet_id = p.id AND pa.user_id = $2
             AND pa.role IN ('carer', 'co_parent')
             AND COALESCE(pa.hidden, false) = false
         )
       )
     ORDER BY p.name`,
    [contactIds, viewerUserId],
  );
  const map = new Map();
  for (const row of result.rows) {
    const list = map.get(row.contact_id) || [];
    list.push(row);
    map.set(row.contact_id, list);
  }
  return map;
}

async function loadWorksAtNames(pool, worksAtIds) {
  const ids = [...new Set(worksAtIds.filter(Boolean))];
  if (ids.length === 0) return new Map();
  const result = await pool.query(
    'SELECT id, name FROM people_contacts WHERE id = ANY($1::uuid[])',
    [ids],
  );
  return new Map(result.rows.map((r) => [r.id, r]));
}

async function loadNextAbsencesByContact(pool, contactIds) {
  if (contactIds.length === 0) return new Map();
  const result = await pool.query(
    `SELECT pap.contact_id,
            pa.id AS absence_id,
            pa.starts_on,
            pa.ends_on,
            array_agg(DISTINCT pap.pet_id) AS pet_ids
     FROM planned_absence_pets pap
     INNER JOIN planned_absences pa ON pa.id = pap.planned_absence_id
     WHERE pap.contact_id = ANY($1::uuid[])
       AND pa.status = 'active'
       AND pa.cancelled_at IS NULL
       AND pa.ends_on >= CURRENT_DATE
     GROUP BY pap.contact_id, pa.id, pa.starts_on, pa.ends_on
     ORDER BY pa.starts_on`,
    [contactIds],
  );
  const map = new Map();
  for (const row of result.rows) {
    if (!map.has(row.contact_id)) {
      map.set(row.contact_id, {
        absence_id: row.absence_id,
        starts_on: row.starts_on,
        ends_on: row.ends_on,
        pet_ids: row.pet_ids || [],
      });
    }
  }
  return map;
}

async function loadLinkedAccessSummaries(pool, linkedUserIds, viewerUserId) {
  const ids = [...new Set(linkedUserIds.filter(Boolean))];
  if (ids.length === 0) return new Map();
  const result = await pool.query(
    `SELECT pa.user_id,
            pa.role,
            pa.pet_id,
            pa.expires_at
     FROM pet_access pa
     INNER JOIN pets p ON p.id = pa.pet_id
     WHERE pa.user_id = ANY($1::uuid[])
       AND p.user_id = $2
       AND COALESCE(pa.hidden, false) = false
     ORDER BY pa.expires_at NULLS LAST`,
    [ids, viewerUserId],
  );
  const map = new Map();
  for (const row of result.rows) {
    if (map.has(row.user_id)) continue;
    const level = row.role === 'co_parent' ? 'co_parent' : 'carer';
    const access = { level };
    if (row.expires_at) {
      access.until = dateToIsoDate(row.expires_at);
    }
    map.set(row.user_id, access);
  }
  return map;
}

async function loadRosterHouseholds(pool, userId) {
  const households = await listHouseholdsForUser(pool, userId);
  if (households.length === 0) return [];

  const householdIds = households.map((h) => h.id);
  const membersResult = await pool.query(
    `SELECT hm.household_id, hm.user_id, hm.access_tier, hm.is_organiser,
            u.first_name, u.last_name
     FROM household_members hm
     INNER JOIN users u ON u.id = hm.user_id
     WHERE hm.household_id = ANY($1::uuid[])
     ORDER BY hm.joined_at`,
    [householdIds],
  );
  const petsResult = await pool.query(
    `SELECT hp.household_id, hp.pet_id, p.user_id AS owner_user_id
     FROM household_pets hp
     INNER JOIN pets p ON p.id = hp.pet_id
     WHERE hp.household_id = ANY($1::uuid[])`,
    [householdIds],
  );

  const petsByHousehold = new Map();
  for (const row of petsResult.rows) {
    const list = petsByHousehold.get(row.household_id) || [];
    list.push(row);
    petsByHousehold.set(row.household_id, list);
  }

  const membersByHousehold = new Map();
  for (const row of membersResult.rows) {
    const list = membersByHousehold.get(row.household_id) || [];
    list.push(row);
    membersByHousehold.set(row.household_id, list);
  }

  return households.map((h) => {
    const pets = petsByHousehold.get(h.id) || [];
    const members = (membersByHousehold.get(h.id) || []).map((m) => {
      const displayName = [m.first_name, m.last_name].filter(Boolean).join(' ').trim()
        || 'Member';
      const owns = pets.filter((p) => p.owner_user_id === m.user_id).map((p) => p.pet_id);
      const shares = pets.filter((p) => p.owner_user_id !== m.user_id).map((p) => p.pet_id);
      return {
        user_id: m.user_id,
        display_name: displayName,
        first_name: m.first_name || '',
        tier: m.access_tier,
        is_organiser: m.is_organiser === true,
        is_you: m.user_id === userId,
        owns_pet_ids: owns,
        shares_pet_ids: shares,
      };
    });
    return {
      id: h.id,
      name: h.name,
      my_tier: h.my_access_tier,
      my_is_organiser: h.my_is_organiser === true,
      members,
    };
  });
}

async function loadPendingInvites(pool, userId) {
  const invites = [];

  const shareResult = await pool.query(
    `SELECT psi.id, psi.invitee_email, psi.created_at,
            COALESCE(array_agg(psip.pet_id) FILTER (WHERE psip.pet_id IS NOT NULL), ARRAY[]::uuid[]) AS pet_ids
     FROM pet_share_invites psi
     LEFT JOIN pet_share_invite_pets psip ON psip.invite_id = psi.id
     WHERE psi.inviter_user_id = $1
       AND psi.status = 'pending'
       AND psi.expires_at > NOW()
     GROUP BY psi.id
     ORDER BY psi.created_at DESC`,
    [userId],
  );
  for (const row of shareResult.rows) {
    invites.push({
      id: row.id,
      source: 'pet_share',
      email: row.invitee_email,
      contact_id: null,
      pet_ids: row.pet_ids || [],
      created_at: timestampToIso(row.created_at),
    });
  }

  const carerResult = await pool.query(
    `SELECT i.id, i.invitee_email, i.contact_id, i.created_at,
            COALESCE(array_agg(ip.pet_id) FILTER (WHERE ip.pet_id IS NOT NULL), ARRAY[]::uuid[]) AS pet_ids
     FROM planned_absence_carer_invites i
     LEFT JOIN planned_absence_carer_invite_pets ip ON ip.invite_id = i.id
     WHERE i.inviter_user_id = $1
       AND i.status = 'pending'
       AND i.expires_at > NOW()
     GROUP BY i.id
     ORDER BY i.created_at DESC`,
    [userId],
  );
  for (const row of carerResult.rows) {
    invites.push({
      id: row.id,
      source: 'absence_carer',
      email: row.invitee_email,
      contact_id: row.contact_id,
      pet_ids: row.pet_ids || [],
      created_at: timestampToIso(row.created_at),
    });
  }

  return invites;
}

/**
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {{ includeInactive?: boolean }} [options]
 */
export async function buildRoster(pool, userId, options = {}) {
  const includeInactive = options.includeInactive === true;
  const directoryIds = await visibleDirectoryIds(pool, userId);
  const contactRows = await loadContactsForDirectories(pool, directoryIds, userId, includeInactive);
  const contactIds = contactRows.map((r) => r.id);
  const linkedUserIds = contactRows.map((r) => r.linked_user_id).filter(Boolean);
  const worksAtIds = contactRows.map((r) => r.works_at_contact_id).filter(Boolean);

  const [
    petsByContact,
    worksAtById,
    nextAbsenceByContact,
    accessByLinkedUser,
    households,
    pendingInvites,
  ] = await Promise.all([
    loadPetsByContactIds(pool, contactIds, userId),
    loadWorksAtNames(pool, worksAtIds),
    loadNextAbsencesByContact(pool, contactIds),
    loadLinkedAccessSummaries(pool, linkedUserIds, userId),
    loadRosterHouseholds(pool, userId),
    loadPendingInvites(pool, userId),
  ]);

  const contacts = contactRows.map((row) => {
    const directory = directoryWire(
      row.directory_id,
      row.directory_household_id ?? null,
    );
    const worksAt = worksAtWire(worksAtById, row.works_at_contact_id);
    const nextAbsence = nextAbsenceWire(nextAbsenceByContact, row.id);
    const access = row.linked_user_id ? accessByLinkedUser.get(row.linked_user_id) : undefined;
    return contactRowToSummary(row, {
      directory,
      household_id: row.directory_household_id,
      pets: petsWireForContact(petsByContact, row.id),
      ...(worksAt ? { works_at: worksAt } : {}),
      ...(nextAbsence ? { next_absence: nextAbsence } : {}),
      ...(access ? { access } : {}),
    });
  });

  return {
    households,
    contacts,
    pending_invites: pendingInvites,
  };
}

/**
 * Summaries for GET /contacts list (additive fields).
 * @param {import('pg').Pool|import('pg').PoolClient} pool
 * @param {string} userId
 * @param {boolean} includeInactive
 */
export async function listContactSummaries(pool, userId, includeInactive = false) {
  const directoryIds = await visibleDirectoryIds(pool, userId);
  const contactRows = await loadContactsForDirectories(pool, directoryIds, userId, includeInactive);
  const contactIds = contactRows.map((r) => r.id);
  const petsByContact = await loadPetsByContactIds(pool, contactIds, userId);

  return contactRows.map((row) => {
    const directory = directoryWire(row.directory_id, row.directory_household_id ?? null);
    const summary = contactRowToSummary(row, {
      directory,
      pets: petsWireForContact(petsByContact, row.id),
    });
    return {
      ...contactRowToMap(row),
      directory: summary.directory,
      group: summary.group,
      status: summary.status,
      pets: summary.pets,
    };
  });
}
