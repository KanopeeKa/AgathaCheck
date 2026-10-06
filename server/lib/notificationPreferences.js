/**
 * Notifications v2 settings matrix (§8) persisted in notification_preferences rows.
 */

import { v4 as uuidv4 } from 'uuid';

export const PREF_NOTIFY_OVERDUE = 'notify_overdue';
export const PREF_NOTIFY_DUE_SOON = 'notify_due_soon';
export const PREF_NOTIFY_COMPLETED = 'notify_completed';
export const PREF_EMAIL_REMINDERS = 'email_reminders_enabled';
export const PREF_REMINDER_DAYS = 'reminder_days_before';
export const PREF_MUTED_PET_IDS = 'muted_pet_ids';
export const PREF_V2_EXPLAINER = 'v2_explainer_dismissed_at';
export const PREF_DEVICE_SECURITY_INTRO_PENDING = 'device_security_intro_pending';
export const PREF_DEVICE_SECURITY_INTRO_DISMISSED =
  'device_security_intro_dismissed_at';
export const PREF_AGATHA_IN_APP = 'agatha_suggestions_in_app';
export const PREF_SETTINGS_MATRIX = 'settings_matrix_v2';
export const PREF_SUGGESTION_TYPES = 'suggestion_types_v2';

export const MATRIX_CATEGORY_INVITES = 'invites_requests';
export const MATRIX_CATEGORY_ACCESS = 'access_membership';
export const MATRIX_CATEGORY_ORG = 'organisation_foster';
export const MATRIX_CATEGORY_SUGGESTIONS = 'agatha_suggestions';
export const MATRIX_CATEGORY_ACCOUNT = 'account_security';
export const MATRIX_CATEGORY_SUBSCRIPTION = 'subscription';

export const SUGGESTION_PUSH_OFF = 'off';
export const SUGGESTION_PUSH_WEEKLY = 'weekly_digest';
export const SUGGESTION_PUSH_INSTANT = 'instant';

export const SUGGESTION_TYPE_KEYS = [
  'suggestionMissingRecurringCare',
  'suggestionWeightTrend',
  'suggestionRepeatedSymptom',
  'suggestionOverduePattern',
  'suggestionStaleRecord',
  'suggestionCareFamily',
  'suggestionShareCoverage',
];

function defaultCategoryChannels({
  inboxAlways = false,
  inboxOn = true,
  push = true,
  email = false,
  locked = false,
  pushMode = null,
}) {
  return {
    inbox: inboxAlways ? 'always' : inboxOn,
    push,
    email,
    locked,
    ...(pushMode ? { push_mode: pushMode } : {}),
  };
}

export function defaultSettingsMatrix() {
  return {
    [MATRIX_CATEGORY_INVITES]: defaultCategoryChannels({
      inboxAlways: true,
      push: true,
      email: true,
    }),
    [MATRIX_CATEGORY_ACCESS]: defaultCategoryChannels({
      inboxAlways: true,
      push: true,
      email: false,
    }),
    [MATRIX_CATEGORY_ORG]: defaultCategoryChannels({
      inboxAlways: true,
      push: true,
      email: true,
    }),
    [MATRIX_CATEGORY_SUGGESTIONS]: defaultCategoryChannels({
      inboxOn: true,
      push: false,
      email: false,
      pushMode: SUGGESTION_PUSH_WEEKLY,
    }),
    [MATRIX_CATEGORY_ACCOUNT]: defaultCategoryChannels({
      inboxAlways: true,
      push: true,
      email: true,
      locked: true,
    }),
    [MATRIX_CATEGORY_SUBSCRIPTION]: defaultCategoryChannels({
      inboxAlways: true,
      push: true,
      email: true,
    }),
  };
}

export function defaultSuggestionTypes() {
  return Object.fromEntries(SUGGESTION_TYPE_KEYS.map((key) => [key, true]));
}

function parseBool(val, defaultValue = false) {
  if (val === true || val === false) return val;
  if (val === undefined || val === null) return defaultValue;
  const s = String(val).toLowerCase();
  if (s === 'true' || s === '1') return true;
  if (s === 'false' || s === '0') return false;
  return defaultValue;
}

function parseJsonObject(val) {
  if (val && typeof val === 'object' && !Array.isArray(val)) return val;
  if (typeof val !== 'string' || !val.trim()) return null;
  try {
    const parsed = JSON.parse(val);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : null;
  } catch (_) {
    return null;
  }
}

function mergeMatrix(stored) {
  const defaults = defaultSettingsMatrix();
  if (!stored) return defaults;
  const merged = { ...defaults };
  for (const key of Object.keys(defaults)) {
    if (!stored[key] || typeof stored[key] !== 'object') continue;
    merged[key] = { ...defaults[key], ...stored[key] };
    if (defaults[key].locked) {
      merged[key] = { ...merged[key], locked: true };
    }
  }
  return merged;
}

function mergeSuggestionTypes(stored) {
  const defaults = defaultSuggestionTypes();
  if (!stored) return defaults;
  const merged = { ...defaults };
  for (const key of SUGGESTION_TYPE_KEYS) {
    if (key in stored) merged[key] = parseBool(stored[key], defaults[key]);
  }
  return merged;
}

export function rowsToPreferenceMap(rows) {
  const map = {};
  for (const row of rows) {
    map[row.preference] = row.value;
  }
  return map;
}

export function preferenceMapToApiDto(map) {
  let mutedPetIds = [];
  const mutedRaw = map[PREF_MUTED_PET_IDS];
  if (Array.isArray(mutedRaw)) {
    mutedPetIds = mutedRaw.map(String);
  } else if (typeof mutedRaw === 'string' && mutedRaw.trim()) {
    try {
      const parsed = JSON.parse(mutedRaw);
      if (Array.isArray(parsed)) mutedPetIds = parsed.map(String);
    } catch (_) {
      mutedPetIds = [];
    }
  }

  const matrixStored = parseJsonObject(map[PREF_SETTINGS_MATRIX]);
  const typesStored = parseJsonObject(map[PREF_SUGGESTION_TYPES]);
  const agathaInApp = parseBool(map[PREF_AGATHA_IN_APP], true);

  const matrix = mergeMatrix(matrixStored);
  if (matrix[MATRIX_CATEGORY_SUGGESTIONS]) {
    matrix[MATRIX_CATEGORY_SUGGESTIONS].inbox = agathaInApp;
  }

  return {
    email_reminders_enabled: parseBool(map[PREF_EMAIL_REMINDERS], false),
    reminder_days_before: parseInt(map[PREF_REMINDER_DAYS], 10) || 1,
    notify_overdue: parseBool(map[PREF_NOTIFY_OVERDUE], true),
    notify_due_soon: parseBool(map[PREF_NOTIFY_DUE_SOON], true),
    notify_completed: parseBool(map[PREF_NOTIFY_COMPLETED], true),
    muted_pet_ids: mutedPetIds,
    v2_explainer_dismissed_at: map[PREF_V2_EXPLAINER] || null,
    show_device_security_intro:
      parseBool(map[PREF_DEVICE_SECURITY_INTRO_PENDING], false)
      && !map[PREF_DEVICE_SECURITY_INTRO_DISMISSED],
    agatha_suggestions_in_app: agathaInApp,
    settings_matrix: matrix,
    suggestion_types: mergeSuggestionTypes(typesStored),
  };
}

function apiMatrixToStored(matrix, agathaInApp) {
  const merged = mergeMatrix(matrix);
  if (merged[MATRIX_CATEGORY_SUGGESTIONS]) {
    merged[MATRIX_CATEGORY_SUGGESTIONS].inbox = agathaInApp;
  }
  if (merged[MATRIX_CATEGORY_ACCOUNT]) {
    merged[MATRIX_CATEGORY_ACCOUNT] = {
      ...defaultSettingsMatrix()[MATRIX_CATEGORY_ACCOUNT],
      ...merged[MATRIX_CATEGORY_ACCOUNT],
      locked: true,
    };
  }
  return merged;
}

export function apiDtoToPreferenceUpdates(body) {
  const updates = {};
  if (body.email_reminders_enabled !== undefined) {
    updates[PREF_EMAIL_REMINDERS] = String(body.email_reminders_enabled === true);
  }
  if (body.reminder_days_before !== undefined) {
    updates[PREF_REMINDER_DAYS] = String(
      Math.max(1, Math.min(14, parseInt(body.reminder_days_before, 10) || 1)),
    );
  }
  if (body.notify_overdue !== undefined) {
    updates[PREF_NOTIFY_OVERDUE] = String(body.notify_overdue !== false);
  }
  if (body.notify_due_soon !== undefined) {
    updates[PREF_NOTIFY_DUE_SOON] = String(body.notify_due_soon !== false);
  }
  if (body.notify_completed !== undefined) {
    updates[PREF_NOTIFY_COMPLETED] = String(body.notify_completed !== false);
  }
  if (body.muted_pet_ids !== undefined) {
    const ids = Array.isArray(body.muted_pet_ids)
      ? body.muted_pet_ids.map(String)
      : [];
    updates[PREF_MUTED_PET_IDS] = JSON.stringify(ids);
  }
  if (body.v2_explainer_dismissed_at !== undefined && body.v2_explainer_dismissed_at) {
    updates[PREF_V2_EXPLAINER] = String(body.v2_explainer_dismissed_at);
  }
  if (
    body.device_security_intro_dismissed_at !== undefined
    && body.device_security_intro_dismissed_at
  ) {
    updates[PREF_DEVICE_SECURITY_INTRO_DISMISSED] = String(
      body.device_security_intro_dismissed_at,
    );
    updates[PREF_DEVICE_SECURITY_INTRO_PENDING] = 'false';
  }

  let agathaInApp;
  if (body.agatha_suggestions_in_app !== undefined) {
    agathaInApp = body.agatha_suggestions_in_app === true;
  } else if (body.settings_matrix?.[MATRIX_CATEGORY_SUGGESTIONS]?.inbox !== undefined) {
    const inbox = body.settings_matrix[MATRIX_CATEGORY_SUGGESTIONS].inbox;
    agathaInApp = inbox === true || inbox === 'true';
  }

  if (body.settings_matrix !== undefined) {
    const currentAgatha = agathaInApp ?? true;
    if (agathaInApp !== undefined) {
      updates[PREF_AGATHA_IN_APP] = String(currentAgatha);
    }
    updates[PREF_SETTINGS_MATRIX] = JSON.stringify(
      apiMatrixToStored(body.settings_matrix, currentAgatha),
    );
  } else if (agathaInApp !== undefined) {
    updates[PREF_AGATHA_IN_APP] = String(agathaInApp);
  }

  if (body.suggestion_types !== undefined) {
    updates[PREF_SUGGESTION_TYPES] = JSON.stringify(
      mergeSuggestionTypes(body.suggestion_types),
    );
  }

  return { updates, agathaTurnedOff: agathaInApp === false };
}

export async function loadNotificationPreferences(pool, userId) {
  const result = await pool.query(
    'SELECT preference, value FROM notification_preferences WHERE user_id = $1',
    [userId],
  );
  return preferenceMapToApiDto(rowsToPreferenceMap(result.rows));
}

export async function upsertNotificationPreference(
  pool,
  userId,
  preference,
  value,
) {
  const existing = await pool.query(
    'SELECT id FROM notification_preferences WHERE user_id = $1 AND preference = $2',
    [userId, preference],
  );
  const stringValue = String(value);
  if (existing.rows.length > 0) {
    await pool.query(
      'UPDATE notification_preferences SET value = $1 WHERE user_id = $2 AND preference = $3',
      [stringValue, userId, preference],
    );
  } else {
    await pool.query(
      'INSERT INTO notification_preferences (id, user_id, preference, value) VALUES ($1, $2, $3, $4)',
      [uuidv4(), userId, preference, stringValue],
    );
  }
}

export function isAgathaSuggestionsInAppEnabled(prefsDto) {
  if (!prefsDto) return true;
  if (prefsDto.agatha_suggestions_in_app === false) return false;
  const inbox = prefsDto.settings_matrix?.[MATRIX_CATEGORY_SUGGESTIONS]?.inbox;
  if (inbox === false || inbox === 'false') return false;
  return true;
}

export function isSuggestionTypeEnabled(prefsDto, wireType) {
  if (!isAgathaSuggestionsInAppEnabled(prefsDto)) return false;
  const types = prefsDto?.suggestion_types || defaultSuggestionTypes();
  if (wireType in types) return types[wireType] !== false;
  return true;
}

export function isRelationshipPushEnabledForPet(prefsDto, petId) {
  if (!prefsDto) return true;
  const muted = prefsDto.muted_pet_ids || [];
  if (petId && muted.includes(String(petId))) return false;
  const access = prefsDto.settings_matrix?.[MATRIX_CATEGORY_ACCESS];
  return access?.push !== false;
}
