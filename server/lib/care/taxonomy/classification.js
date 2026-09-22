import { deriveLegacyHealthEntryType, defaultsForCareFamily, loadCareTaxonomy } from './index.js';

export const CARE_SETTINGS = new Set(['home', 'vet', 'other']);
export const CARE_PLANNING_MODES = new Set(['planned', 'unplanned']);
export const CARE_IMPORTANCE_LEVELS = new Set(['essential', 'recommended', 'optional']);

/**
 * Phase B: clients must not send legacy `type` — server derives it.
 * @param {object} data
 * @returns {{ ok: true } | { ok: false, error: string }}
 */
export function rejectClientTypeField(data) {
  const raw = data?.type;
  if (raw !== undefined && raw !== null && raw !== '') {
    return { ok: false, error: 'type is server-derived; omit type from the request body' };
  }
  return { ok: true };
}

/**
 * Resolve classification columns for create/update.
 * @param {object} params
 * @param {object} params.data request body
 * @param {string|null} params.careFamily validated care_family
 * @param {string} params.frequency
 * @param {string|null} params.completedOn ISO date or null
 * @param {string|null} params.nextDueDate ISO date or null
 * @param {object|null} [params.existing] existing row on update
 * @returns {{ ok: true, value: object } | { ok: false, error: string }}
 */
export function resolveClassificationForWrite({
  data,
  careFamily,
  frequency,
  completedOn,
  nextDueDate,
  existing = null,
}) {
  const taxonomy = loadCareTaxonomy();
  const familyDefaults = defaultsForCareFamily(careFamily);

  const settingRaw = data.care_setting ?? data.careSetting
    ?? existing?.care_setting
    ?? familyDefaults.care_setting;
  const careSetting = String(settingRaw);
  if (!CARE_SETTINGS.has(careSetting)) {
    return { ok: false, error: `Invalid care_setting: ${careSetting}` };
  }

  const planningRaw = data.care_planning ?? data.carePlanning
    ?? existing?.care_planning
    ?? 'planned';
  const carePlanning = String(planningRaw);
  if (!CARE_PLANNING_MODES.has(carePlanning)) {
    return { ok: false, error: `Invalid care_planning: ${carePlanning}` };
  }

  const isRecurring = frequency && frequency !== 'once';
  if (isRecurring && carePlanning === 'unplanned') {
    return { ok: false, error: 'unplanned entries cannot recur' };
  }
  if (carePlanning === 'unplanned' && frequency !== 'once') {
    return { ok: false, error: 'unplanned entries must use frequency once' };
  }

  const defaultImportance = familyDefaults.care_importance;
  const explicitImportance = data.care_importance ?? data.careImportance;
  const careImportance = explicitImportance != null && explicitImportance !== ''
    ? String(explicitImportance)
    : (existing?.care_importance ?? defaultImportance);
  if (!CARE_IMPORTANCE_LEVELS.has(careImportance)) {
    return { ok: false, error: `Invalid care_importance: ${careImportance}` };
  }

  const importanceOverridden = Boolean(
    explicitImportance != null
    && explicitImportance !== ''
    && explicitImportance !== defaultImportance,
  );

  if (carePlanning === 'unplanned') {
    if (!completedOn) {
      return { ok: false, error: 'completed_on is required for unplanned entries' };
    }
    if (nextDueDate) {
      return { ok: false, error: 'unplanned entries cannot have next_due_date' };
    }
  }

  const legacyType = deriveLegacyHealthEntryType(careFamily, careSetting);

  let remindDaysBefore = data.remind_days_before ?? data.remindDaysBefore;
  if (carePlanning === 'unplanned') {
    remindDaysBefore = 0;
  } else if (remindDaysBefore === undefined || remindDaysBefore === null) {
    remindDaysBefore = existing?.remind_days_before ?? 1;
  }

  return {
    ok: true,
    value: {
      care_setting: careSetting,
      care_planning: carePlanning,
      care_importance: careImportance,
      importance_overridden: importanceOverridden,
      type: legacyType,
      remind_days_before: remindDaysBefore,
    },
  };
}
