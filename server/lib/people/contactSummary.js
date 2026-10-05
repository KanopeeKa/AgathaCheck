import { dateToIsoDate } from '../calendarDate.js';
import { contactGroup } from './inference.js';

const HANDOVER_RELATIONSHIP_KINDS = new Set([
  'primary_vet',
  'out_of_hours_vet',
  'emergency_contact',
  'care_provider',
]);

export function contactStatusFromRow(row) {
  return row.inactive_at ? 'inactive' : 'active';
}

/**
 * @param {{ type: 'personal' | 'household', household_id?: string|null }} directory
 */
export function directoryWire(directoryId, householdId = null) {
  if (householdId) {
    return { type: 'household', household_id: householdId };
  }
  return { type: 'personal', household_id: null };
}

/**
 * @param {object} row people_contacts row with roles[]
 * @param {object} [extras]
 */
export function contactRowToSummary(row, extras = {}) {
  const roles = Array.isArray(row.roles) ? row.roles : [];
  const kind = row.kind || 'person';
  const summary = {
    id: row.id,
    directory: extras.directory || directoryWire(row.directory_id, extras.household_id ?? null),
    kind,
    name: row.name,
    roles,
    group: contactGroup(roles, kind),
    status: contactStatusFromRow(row),
    linked_user_id: row.linked_user_id ?? null,
    pets: extras.pets || [],
  };
  if (extras.works_at) summary.works_at = extras.works_at;
  if (extras.next_absence) summary.next_absence = extras.next_absence;
  if (extras.access) summary.access = extras.access;
  return summary;
}

export function isHandoverRelationshipKind(kind) {
  return HANDOVER_RELATIONSHIP_KINDS.has(kind);
}

/**
 * @param {Map<string, object[]>} petsByContact
 * @param {string} contactId
 */
export function petsWireForContact(petsByContact, contactId) {
  const rows = petsByContact.get(contactId) || [];
  return rows.map((r) => ({
    pet_id: r.pet_id,
    pet_name: r.pet_name,
    relationship_kind: r.relationship_kind,
    is_primary: r.is_primary === true || r.is_primary === 't',
  }));
}

/**
 * @param {Map<string, object>} worksAtById
 * @param {string|null} worksAtContactId
 */
export function worksAtWire(worksAtById, worksAtContactId) {
  if (!worksAtContactId) return null;
  const row = worksAtById.get(worksAtContactId);
  if (!row) return { id: worksAtContactId, name: '' };
  return { id: row.id, name: row.name };
}

/**
 * @param {Map<string, object>} nextAbsenceByContact
 * @param {string} contactId
 */
export function nextAbsenceWire(nextAbsenceByContact, contactId) {
  const row = nextAbsenceByContact.get(contactId);
  if (!row) return null;
  return {
    absence_id: row.absence_id,
    starts_on: dateToIsoDate(row.starts_on),
    ends_on: dateToIsoDate(row.ends_on),
    pet_ids: row.pet_ids || [],
  };
}
