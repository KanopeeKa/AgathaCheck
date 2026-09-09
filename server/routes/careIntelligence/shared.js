import { dateToIsoDate } from '../../lib/calendarDate.js';

export const ENGINE_VERSION = '1.0.0';
export const KNOWLEDGE_VERSION = '1.0.0';

import { CIM_SUGGESTION_CARE_FAMILIES } from '../../lib/care/enums.js';

export const CARE_FAMILIES = CIM_SUGGESTION_CARE_FAMILIES;

export const RECOMMENDATION_STATUSES = new Set([
  'pending',
  'accepted',
  'adjusted',
  'dismissed',
  'not_relevant',
]);

export const RESPONSE_ACTIONS = new Set([
  'accept',
  'adjust',
  'dismiss',
  'not_relevant',
]);

export const SUPPORTED_SPECIES = new Set(['cat', 'dog']);

export const SUGGESTION_CATALOG = {
  weight_monitoring_rhythm: {
    care_family: 'weight_monitoring',
    suggestion_key: 'weight_monitoring_rhythm',
    suggested_name: 'Weight check',
    suggested_frequency: 'monthly',
    suggested_frequency_interval: 1,
    suggested_health_entry_type: 'other',
    rationale_key: 'careSuggestionWeightMonitoringWhy',
  },
  dental_review_rhythm: {
    care_family: 'dental',
    suggestion_key: 'dental_review_rhythm',
    suggested_name: 'Dental check',
    suggested_frequency: 'yearly',
    suggested_frequency_interval: 1,
    suggested_health_entry_type: 'vet_visit',
    rationale_key: 'careSuggestionDentalWhy',
  },
  wellness_review_rhythm: {
    care_family: 'wellness_review',
    suggestion_key: 'wellness_review_rhythm',
    suggested_name: 'Wellness review',
    suggested_frequency: 'yearly',
    suggested_frequency_interval: 1,
    suggested_health_entry_type: 'vet_visit',
    rationale_key: 'careSuggestionWellnessWhy',
  },
};

export function recommendationToMap(row) {
  return {
    id: row.id,
    pet_id: row.pet_id,
    care_family: row.care_family,
    suggestion_key: row.suggestion_key,
    status: row.status,
    engine_version: row.engine_version,
    knowledge_version: row.knowledge_version,
    suggested_name: row.suggested_name,
    suggested_frequency: row.suggested_frequency,
    suggested_frequency_interval: row.suggested_frequency_interval,
    suggested_health_entry_type: row.suggested_health_entry_type,
    rationale_key: row.rationale_key,
    health_entry_id: row.health_entry_id,
    responded_at: row.responded_at ? row.responded_at.toISOString() : null,
    created_at: row.created_at ? row.created_at.toISOString() : null,
    updated_at: row.updated_at ? row.updated_at.toISOString() : null,
  };
}

export function monthsBetween(startDate, endDate) {
  if (!startDate || !endDate) return 0;
  const start = new Date(startDate);
  const end = new Date(endDate);
  return (end.getFullYear() - start.getFullYear()) * 12
    + (end.getMonth() - start.getMonth());
}

export function normalizeSpecies(species) {
  return (species || '').trim().toLowerCase();
}

export function todayCalendarDate() {
  return dateToIsoDate(new Date());
}
