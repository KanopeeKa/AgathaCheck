/** Wire types for Agatha Suggestions wave 1 (S1, S2). */
export const SUGGESTION_TYPE_MISSING_RECURRING = 'suggestionMissingRecurringCare';
export const SUGGESTION_TYPE_WEIGHT_TREND = 'suggestionWeightTrend';

export const SUGGESTION_TTL_DAYS = 14;
export const DEFAULT_SUGGESTION_CONFIDENCE = 0.85;
export const MIN_SUGGESTION_CONFIDENCE = 0.7;

/** FR-RL-1 / FR-RL-2 */
export const MAX_NEW_SUGGESTIONS_PER_PET_7D = 3;
export const MAX_NEW_SUGGESTIONS_PER_USER_7D = 5;
export const MAX_ACTIVE_SUGGESTIONS_PER_USER = 10;

/** S2 — weight change threshold (spec AC-SG-2 uses 5%). */
export const WEIGHT_TREND_THRESHOLD_PCT = 5;
export const WEIGHT_TREND_WINDOW_DAYS = 90;
export const WEIGHT_TREND_MIN_ENTRIES = 2;

/** S1 — parasite prevention rhythm (deworming) for cats/dogs. */
export const S1_CARE_FAMILY = 'parasite_prevention';
export const S1_MIN_AGE_MONTHS = 3;

export const SUPPORTED_SPECIES = new Set(['cat', 'dog']);
