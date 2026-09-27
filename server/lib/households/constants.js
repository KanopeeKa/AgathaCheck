export const HOUSEHOLD_TIER_FULL = 'full_access';
export const HOUSEHOLD_TIER_LOG = 'can_log_care';
export const HOUSEHOLD_TIERS = [HOUSEHOLD_TIER_FULL, HOUSEHOLD_TIER_LOG];

export function isHouseholdTier(value) {
  return HOUSEHOLD_TIERS.includes(value);
}

/** Organisers must stay on full_access (D13). */
export function normalizeMemberTier({ accessTier, isOrganiser }) {
  if (isOrganiser) return HOUSEHOLD_TIER_FULL;
  return accessTier === HOUSEHOLD_TIER_LOG ? HOUSEHOLD_TIER_LOG : HOUSEHOLD_TIER_FULL;
}
