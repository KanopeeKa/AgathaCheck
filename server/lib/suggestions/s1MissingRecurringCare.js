import {
  S1_CARE_FAMILY,
  S1_MIN_AGE_MONTHS,
  SUGGESTION_TYPE_MISSING_RECURRING,
  SUPPORTED_SPECIES,
} from './suggestionConstants.js';

function monthsBetween(startDate, endDate) {
  if (!startDate || !endDate) return 0;
  const start = new Date(startDate);
  const end = new Date(endDate);
  return (end.getFullYear() - start.getFullYear()) * 12
    + (end.getMonth() - start.getMonth());
}

function isRecurringEntry(entry) {
  return entry.frequency && entry.frequency !== 'once';
}

export function buildS1DedupeKey(petId) {
  return `missing_recurring:${S1_CARE_FAMILY}:${petId}`;
}

/**
 * @param {object} pet — row from pets
 * @param {object[]} healthEntries
 * @returns {null | { dedupeKey, title, message, confidence, payload }}
 */
export function evaluateS1MissingRecurringCare(pet, healthEntries, now = new Date()) {
  const species = (pet.species || '').trim().toLowerCase();
  if (!SUPPORTED_SPECIES.has(species)) return null;
  if (pet.passed_away) return null;

  const ageMonths = monthsBetween(pet.date_of_birth, now);
  if (ageMonths < S1_MIN_AGE_MONTHS) return null;

  const hasRecurring = healthEntries.some(
    (e) => e.care_family === S1_CARE_FAMILY && isRecurringEntry(e),
  );
  if (hasRecurring) return null;

  const petName = pet.name || 'your pet';
  const speciesHint = species === 'cat'
    ? 'Cats usually need parasite prevention every 3 months.'
    : 'Dogs usually need parasite prevention on a regular schedule.';
  const title = `${petName}: consider parasite prevention`;
  const message = `${petName} has no recurring parasite prevention reminder. ${speciesHint}`;

  return {
    wireType: SUGGESTION_TYPE_MISSING_RECURRING,
    dedupeKey: buildS1DedupeKey(pet.id),
    title,
    message,
    confidence: 0.82,
    payload: {
      care_family: S1_CARE_FAMILY,
      primary_action: 'add_reminder',
      evidence: {
        species,
        age_months: ageMonths,
        recurring_care_present: false,
      },
    },
  };
}
