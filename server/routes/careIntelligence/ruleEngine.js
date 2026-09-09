import {
  ENGINE_VERSION,
  KNOWLEDGE_VERSION,
  SUGGESTION_CATALOG,
  SUPPORTED_SPECIES,
  monthsBetween,
  normalizeSpecies,
  todayCalendarDate,
} from './shared.js';

function isRecurring(entry) {
  return entry.frequency && entry.frequency !== 'once';
}

function entryCareFamily(entry) {
  return entry.care_family || null;
}

export function hasActiveRecurringCare(entries, careFamily) {
  return entries.some((entry) => (
    isRecurring(entry) && entryCareFamily(entry) === careFamily
  ));
}

function hasVetCadence(entries, careFamily) {
  return entries.some((entry) => (
    entryCareFamily(entry) === careFamily
    && entry.care_source === 'vet_instruction'
  ));
}

function isSuppressedByResponse(existingRows, careFamily) {
  return existingRows.some((row) => (
    row.care_family === careFamily
    && (row.status === 'not_relevant' || row.status === 'accepted' || row.status === 'adjusted')
  ));
}

function isDismissedRecently(existingRows, careFamily) {
  return existingRows.some((row) => (
    row.care_family === careFamily && row.status === 'dismissed'
  ));
}

/**
 * Crisp candidate rules for Phase C — three families only.
 */
export function evaluateCareRecommendationCandidates({
  pet,
  healthEntries,
  existingRecommendations,
  now = new Date(),
}) {
  const species = normalizeSpecies(pet.species);
  if (!SUPPORTED_SPECIES.has(species)) {
    return [];
  }

  const ageMonths = monthsBetween(pet.date_of_birth, now);
  const candidates = [];

  const maybeAdd = (catalogKey, predicate) => {
    const template = SUGGESTION_CATALOG[catalogKey];
    if (!template) return;
    const { care_family: careFamily } = template;
    if (!predicate()) return;
    if (hasActiveRecurringCare(healthEntries, careFamily)) return;
    if (hasVetCadence(healthEntries, careFamily)) return;
    if (isSuppressedByResponse(existingRecommendations, careFamily)) return;
    if (isDismissedRecently(existingRecommendations, careFamily)) return;
    candidates.push({
      ...template,
      engine_version: ENGINE_VERSION,
      knowledge_version: KNOWLEDGE_VERSION,
    });
  };

  maybeAdd('weight_monitoring_rhythm', () => ageMonths >= 6);
  maybeAdd('dental_review_rhythm', () => ageMonths >= 12);
  maybeAdd('wellness_review_rhythm', () => ageMonths >= 12);

  return candidates;
}

export function buildRecommendationInsertValues(petId, candidate, id) {
  return [
    id,
    petId,
    candidate.care_family,
    candidate.suggestion_key,
    'pending',
    candidate.engine_version,
    candidate.knowledge_version,
    candidate.suggested_name,
    candidate.suggested_frequency,
    candidate.suggested_frequency_interval,
    candidate.suggested_health_entry_type,
    candidate.rationale_key,
  ];
}

export function buildAcceptedHealthEntry({
  petId,
  userId,
  recommendation,
  adjust,
}) {
  const frequency = adjust?.frequency || recommendation.suggested_frequency;
  const frequencyInterval = adjust?.frequency_interval
    ?? adjust?.frequencyInterval
    ?? recommendation.suggested_frequency_interval;
  const startDate = todayCalendarDate();
  return {
    petId,
    userId,
    name: recommendation.suggested_name,
    type: recommendation.suggested_health_entry_type,
    frequency,
    frequencyInterval,
    startDate,
    nextDueDate: startDate,
    careFamily: recommendation.care_family,
    careSource: adjust ? 'agatha_adjusted' : 'agatha_accepted',
  };
}
