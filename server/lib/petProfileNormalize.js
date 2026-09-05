/** Canonical pet profile values for species and gender on the wire. */

const SPECIES_ALIASES = Object.freeze({
  dog: 'Dog',
  cat: 'Cat',
  bird: 'Bird',
  fish: 'Fish',
  rabbit: 'Rabbit',
  hamster: 'Hamster',
  ferret: 'Ferret',
  'horse / poney': 'Horse / Poney',
  'horse / pony': 'Horse / Poney',
  other: 'Other',
});

const GENDER_ALIASES = Object.freeze({
  male: 'Male',
  female: 'Female',
  m: 'Male',
  f: 'Female',
});

const CANONICAL_SPECIES = new Set(Object.values(SPECIES_ALIASES));
const CANONICAL_GENDERS = new Set(['Male', 'Female']);

/**
 * @param {unknown} raw
 * @returns {string}
 */
export function normalizeSpecies(raw) {
  if (raw == null) return '';
  const trimmed = String(raw).trim();
  if (!trimmed) return '';
  if (CANONICAL_SPECIES.has(trimmed)) return trimmed;
  const alias = SPECIES_ALIASES[trimmed.toLowerCase()];
  return alias || trimmed;
}

/**
 * @param {unknown} raw
 * @returns {string|null}
 */
export function normalizeGender(raw) {
  if (raw == null) return null;
  const trimmed = String(raw).trim();
  if (!trimmed) return null;
  if (CANONICAL_GENDERS.has(trimmed)) return trimmed;
  const alias = GENDER_ALIASES[trimmed.toLowerCase()];
  return alias || trimmed;
}

const MAX_PHOTO_PATH_LENGTH = 512;

/**
 * Accept only server-stored upload URLs for photo_path writes.
 * Rejects inline base64/data URLs so large payloads cannot be persisted via JSON.
 *
 * @param {unknown} photoPath
 * @returns {{ ok: true, value: string|null } | { ok: false, error: string }}
 */
export function sanitizePhotoPathForWrite(photoPath) {
  if (photoPath == null) return { ok: true, value: null };
  if (typeof photoPath !== 'string') {
    return { ok: false, error: 'Photo must be uploaded using the photo endpoint' };
  }
  const trimmed = photoPath.trim();
  if (!trimmed) return { ok: true, value: null };
  if (trimmed.startsWith('data:')) {
    return { ok: false, error: 'Photo must be uploaded using the photo endpoint' };
  }
  if (trimmed.length > MAX_PHOTO_PATH_LENGTH) {
    return { ok: false, error: 'Photo must be uploaded using the photo endpoint' };
  }
  if (!trimmed.startsWith('/uploads/')) {
    return { ok: false, error: 'Invalid photo path' };
  }
  if (trimmed.includes('..') || trimmed.includes('\\')) {
    return { ok: false, error: 'Invalid photo path' };
  }
  return { ok: true, value: trimmed };
}
