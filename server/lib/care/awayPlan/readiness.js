import {
  COVERAGE_STATE_ALL_COMPLETED,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
} from '../carePeriodCoverage.js';
import { carerRowToMap } from '../plannedAbsence.js';

export const CARER_COVERAGE_ALL_HAVE_CARERS = 'all_have_carers';
export const CARER_COVERAGE_SOME_HAVE_CARERS = 'some_have_carers';
export const CARER_COVERAGE_NONE_HAVE_CARERS = 'none_have_carers';

export const TILE_COPY_SOURCE_CARER = 'carer_coverage';
export const TILE_COPY_SOURCE_CARE = 'care_coverage';

export const CARER_COVERAGE_COPY_KEYS = {
  [CARER_COVERAGE_ALL_HAVE_CARERS]: 'awayPlanningCarerCoverageAllHaveCarers',
  [CARER_COVERAGE_SOME_HAVE_CARERS]: 'awayPlanningCarerCoverageSomeHaveCarers',
  [CARER_COVERAGE_NONE_HAVE_CARERS]: 'awayPlanningCarerCoverageNoneHaveCarers',
};

export const TILE_COPY_CARER_NONE = 'awayPlanningTileCarerNone';
export const TILE_COPY_CARER_SOME = 'awayPlanningTileCarerSome';

export const CARE_COVERAGE_COPY_KEYS = {
  [COVERAGE_STATE_NOTHING_SCHEDULED]: 'careContextCoverageNothingScheduled',
  [COVERAGE_STATE_ALL_COMPLETED]: 'careContextCoverageAllCompleted',
  [COVERAGE_STATE_NO_UNRESOLVED_ITEMS]: 'careContextCoverageNoUnresolved',
  [COVERAGE_STATE_HAS_ITEMS_TO_REVIEW]: 'careContextCoverageHasItemsToReview',
  [COVERAGE_STATE_INDETERMINATE]: 'careContextCoverageIndeterminate',
};

const COVERAGE_STATE_PRIORITY = [
  COVERAGE_STATE_INDETERMINATE,
  COVERAGE_STATE_HAS_ITEMS_TO_REVIEW,
  COVERAGE_STATE_NOTHING_SCHEDULED,
  COVERAGE_STATE_NO_UNRESOLVED_ITEMS,
  COVERAGE_STATE_ALL_COMPLETED,
];

/**
 * @param {object} petRow
 */
export function petHasCarer(petRow) {
  const mapped = carerRowToMap(petRow);
  if (!mapped.carer_kind || mapped.carer_removed) {
    return false;
  }
  if (mapped.carer_kind === 'note_only' && !mapped.carer_name) {
    return false;
  }
  return true;
}

/**
 * @param {object[]} petCarers
 */
export function deriveCarerCoverage(petCarers) {
  const pets = petCarers || [];
  const petsTotal = pets.length;
  const petsWithCarer = pets.filter((row) => petHasCarer(row)).length;

  let state;
  if (petsWithCarer === 0) {
    state = CARER_COVERAGE_NONE_HAVE_CARERS;
  } else if (petsWithCarer === petsTotal) {
    state = CARER_COVERAGE_ALL_HAVE_CARERS;
  } else {
    state = CARER_COVERAGE_SOME_HAVE_CARERS;
  }

  return {
    state,
    pets_with_carer: petsWithCarer,
    pets_total: petsTotal,
    copy_key: CARER_COVERAGE_COPY_KEYS[state],
  };
}

/**
 * Pick the least-reassuring coverage state across pets (D-AWAY-002: no cross-pet reassurance).
 *
 * @param {{ coverage: object, projection?: object }[]} perPetResults
 */
export function aggregateCareCoverage(perPetResults) {
  if (!perPetResults.length) {
    return {
      policy_version: '1',
      coverage_state: COVERAGE_STATE_NOTHING_SCHEDULED,
      reason_codes: [],
      reassurance_available: true,
      pending_item_count: 0,
    };
  }

  let selected = perPetResults[0].coverage;
  let selectedPriority = COVERAGE_STATE_PRIORITY.indexOf(selected.coverage_state);
  let pendingItemCount = 0;

  for (const { coverage, projection } of perPetResults) {
    const priority = COVERAGE_STATE_PRIORITY.indexOf(coverage.coverage_state);
    if (priority >= 0 && (selectedPriority < 0 || priority < selectedPriority)) {
      selected = coverage;
      selectedPriority = priority;
    }
    if (coverage.coverage_state === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW) {
      pendingItemCount += (projection?.items || []).filter((item) => item.status === 'pending').length;
    }
  }

  return {
    ...selected,
    pending_item_count: pendingItemCount,
  };
}

/**
 * @param {object} careCoverage
 */
function careCoverageCopyKey(careCoverage) {
  return CARE_COVERAGE_COPY_KEYS[careCoverage.coverage_state];
}

/**
 * @param {object} carerCoverage from deriveCarerCoverage
 * @param {object} careCoverage from evaluateCarePeriodCoverage or aggregateCareCoverage
 */
export function deriveAwayPlanReadiness(carerCoverage, careCoverage) {
  const careFact = {
    policy_version: careCoverage.policy_version,
    coverage_state: careCoverage.coverage_state,
    reason_codes: careCoverage.reason_codes || [],
    reassurance_available: careCoverage.reassurance_available,
    copy_key: careCoverageCopyKey(careCoverage),
  };

  if (
    careCoverage.coverage_state === COVERAGE_STATE_HAS_ITEMS_TO_REVIEW
    && careCoverage.pending_item_count != null
  ) {
    careFact.copy_params = { count: careCoverage.pending_item_count };
  }

  const carerFact = {
    state: carerCoverage.state,
    pets_with_carer: carerCoverage.pets_with_carer,
    pets_total: carerCoverage.pets_total,
    copy_key: carerCoverage.copy_key,
  };

  let tileCopy;
  if (carerCoverage.state === CARER_COVERAGE_NONE_HAVE_CARERS) {
    tileCopy = {
      source: TILE_COPY_SOURCE_CARER,
      copy_key: TILE_COPY_CARER_NONE,
    };
  } else if (carerCoverage.state === CARER_COVERAGE_SOME_HAVE_CARERS) {
    tileCopy = {
      source: TILE_COPY_SOURCE_CARER,
      copy_key: TILE_COPY_CARER_SOME,
    };
  } else {
    tileCopy = {
      source: TILE_COPY_SOURCE_CARE,
      copy_key: careFact.copy_key,
    };
    if (careFact.copy_params) {
      tileCopy.copy_params = careFact.copy_params;
    }
  }

  return {
    carer_coverage: carerFact,
    care_coverage: careFact,
    tile_copy: tileCopy,
  };
}
