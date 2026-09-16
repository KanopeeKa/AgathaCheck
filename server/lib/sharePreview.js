/**
 * Scoped share preview DTO (F-03).
 * Anonymous preview must not expose health, vet, insurance, chip, or owner email.
 */
import { dateToIsoDate } from './calendarDate.js';

/**
 * @param {object} row pets row
 */
export function buildSharePreviewPet(row) {
  const dob = row.date_of_birth ? dateToIsoDate(row.date_of_birth) : null;
  return {
    name: row.name,
    species: row.species,
    breed: row.breed || '',
    age: row.age ?? null,
    date_of_birth: dob,
    photo_path: row.photo_path || null,
  };
}

/**
 * @param {object} row users row (owner)
 */
export function buildSharePreviewOwner(row) {
  return {
    first_name: row?.first_name || '',
  };
}

/**
 * @param {object} link pet_share_links row
 * @param {object} petRow pets row
 * @param {object} ownerRow users row
 */
export function buildSharePreviewResponse(link, petRow, ownerRow) {
  const expiresAt = link.expires_at
    ? (link.expires_at.toISOString?.() || String(link.expires_at))
    : null;
  return {
    link_status: link.status || 'pending',
    expires_at: expiresAt,
    access_role: link.access_role || 'carer',
    pet: buildSharePreviewPet(petRow),
    owner: buildSharePreviewOwner(ownerRow),
  };
}
