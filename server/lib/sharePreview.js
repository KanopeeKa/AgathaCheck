/**
 * Scoped share preview DTO (F-03).
 * Anonymous preview must not expose health, vet, insurance, chip, or owner email.
 */
import { dateToIsoDate } from './calendarDate.js';

const PET_COLOR_PALETTE = [
  0xFF7E57C2, 0xFF9575CD, 0xFF5C6BC0, 0xFF7986CB, 0xFF4DB6AC,
  0xFF81C784, 0xFF4FC3F7, 0xFFBA68C8, 0xFFF06292, 0xFFE57373,
  0xFFFFB74D, 0xFFA1887F, 0xFF90A4AE, 0xFF64B5F6, 0xFFAED581,
];

function resolveColorValue(raw) {
  if (raw == null) return null;
  const v = typeof raw === 'number' ? raw : parseInt(raw, 10);
  if (isNaN(v)) return null;
  if (v < PET_COLOR_PALETTE.length) return PET_COLOR_PALETTE[v];
  return v;
}

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
    dateOfBirth: dob,
    photoPath: row.photo_path || null,
    colorValue: resolveColorValue(row.color_index),
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
    pet: buildSharePreviewPet(petRow),
    owner: buildSharePreviewOwner(ownerRow),
  };
}
