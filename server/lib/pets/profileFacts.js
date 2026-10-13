/**
 * Profile fact fields (identification / neuter) — parse, merge, normalise for pet writes.
 */

export const PROFILE_FACT_STATUSES = Object.freeze(['yes', 'no', 'unknown']);

const STATUS_KEYS = [
  'identification_status',
  'neuter_status',
  'identification_status_source',
  'neuter_status_source',
  'identification_status_updated_at',
  'neuter_status_updated_at',
  'chip_dismissed',
  'neuter_dismissed',
];

function bodyHas(body, camel, snake) {
  return Object.prototype.hasOwnProperty.call(body, camel)
    || Object.prototype.hasOwnProperty.call(body, snake);
}

function bodyValue(body, camel, snake) {
  if (Object.prototype.hasOwnProperty.call(body, camel)) return body[camel];
  if (Object.prototype.hasOwnProperty.call(body, snake)) return body[snake];
  return undefined;
}

/**
 * @param {unknown} raw
 * @returns {{ ok: true, value: string } | { ok: false, error: string }}
 */
export function parseProfileFactStatus(raw) {
  if (raw === undefined || raw === null || raw === '') {
    return { ok: false, error: 'invalid_profile_fact_status' };
  }
  const value = String(raw).toLowerCase();
  if (!PROFILE_FACT_STATUSES.includes(value)) {
    return { ok: false, error: 'invalid_profile_fact_status' };
  }
  return { ok: true, value };
}

/**
 * @param {Record<string, unknown>} body
 * @param {Record<string, unknown>} existingRow
 * @returns {{ ok: true, patch: Record<string, unknown> } | { ok: false, error: string }}
 */
export function mergeProfileFactsFromBody(body, existingRow) {
  const patch = {};

  const idStatusProvided = bodyHas(body, 'identificationStatus', 'identification_status');
  const neuterStatusProvided = bodyHas(body, 'neuterStatus', 'neuter_status');

  if (idStatusProvided) {
    const parsed = parseProfileFactStatus(bodyValue(body, 'identificationStatus', 'identification_status'));
    if (!parsed.ok) return { ok: false, error: 'Invalid identification_status' };
    patch.identification_status = parsed.value;
  } else if (existingRow.identification_status != null) {
    patch.identification_status = existingRow.identification_status;
  } else {
    patch.identification_status = 'unknown';
  }

  if (neuterStatusProvided) {
    const parsed = parseProfileFactStatus(bodyValue(body, 'neuterStatus', 'neuter_status'));
    if (!parsed.ok) return { ok: false, error: 'Invalid neuter_status' };
    patch.neuter_status = parsed.value;
  } else if (existingRow.neuter_status != null) {
    patch.neuter_status = existingRow.neuter_status;
  } else {
    patch.neuter_status = 'unknown';
  }

  if (bodyHas(body, 'identificationStatusSource', 'identification_status_source')) {
    patch.identification_status_source = bodyValue(body, 'identificationStatusSource', 'identification_status_source') ?? null;
  } else {
    patch.identification_status_source = existingRow.identification_status_source ?? null;
  }

  if (bodyHas(body, 'neuterStatusSource', 'neuter_status_source')) {
    patch.neuter_status_source = bodyValue(body, 'neuterStatusSource', 'neuter_status_source') ?? null;
  } else {
    patch.neuter_status_source = existingRow.neuter_status_source ?? null;
  }

  if (bodyHas(body, 'identificationStatusUpdatedAt', 'identification_status_updated_at')) {
    patch.identification_status_updated_at = bodyValue(body, 'identificationStatusUpdatedAt', 'identification_status_updated_at') ?? null;
  } else {
    patch.identification_status_updated_at = existingRow.identification_status_updated_at ?? null;
  }

  if (bodyHas(body, 'neuterStatusUpdatedAt', 'neuter_status_updated_at')) {
    patch.neuter_status_updated_at = bodyValue(body, 'neuterStatusUpdatedAt', 'neuter_status_updated_at') ?? null;
  } else {
    patch.neuter_status_updated_at = existingRow.neuter_status_updated_at ?? null;
  }

  if (bodyHas(body, 'chipDismissed', 'chip_dismissed')) {
    patch.chip_dismissed = Boolean(bodyValue(body, 'chipDismissed', 'chip_dismissed'));
  } else {
    patch.chip_dismissed = existingRow.chip_dismissed || false;
  }

  if (bodyHas(body, 'neuterDismissed', 'neuter_dismissed')) {
    patch.neuter_dismissed = Boolean(bodyValue(body, 'neuterDismissed', 'neuter_dismissed'));
  } else {
    patch.neuter_dismissed = existingRow.neuter_dismissed || false;
  }

  if (Object.prototype.hasOwnProperty.call(body, 'chipId')) {
    patch.chip_id = body.chipId == null ? '' : String(body.chipId);
  } else if (Object.prototype.hasOwnProperty.call(body, 'chip_id')) {
    patch.chip_id = body.chip_id == null ? '' : String(body.chip_id);
  } else {
    patch.chip_id = existingRow.chip_id ?? '';
  }

  return { ok: true, patch };
}

/**
 * @param {Record<string, unknown>} merged
 * @param {string | null} neuteredDateIso
 * @returns {{ ok: true, patch: Record<string, unknown> } | { ok: false, error: string }}
 */
export function normaliseProfileFacts(merged, neuteredDateIso) {
  const patch = { ...merged };
  const chip = String(patch.chip_id ?? '').trim();
  if (chip && (patch.identification_status === 'unknown' || patch.identification_status === 'no')) {
    patch.identification_status = 'yes';
  }
  if (neuteredDateIso && patch.neuter_status === 'no') {
    return { ok: false, error: 'neuter_status cannot be no when neutered_date is set' };
  }
  return { ok: true, patch };
}

export function profileFactDefaultsForCreate(body) {
  const idRaw = bodyValue(body, 'identificationStatus', 'identification_status');
  const neuterRaw = bodyValue(body, 'neuterStatus', 'neuter_status');
  let identification_status = 'unknown';
  let neuter_status = 'unknown';
  if (idRaw !== undefined) {
    const parsed = parseProfileFactStatus(idRaw);
    if (!parsed.ok) return { ok: false, error: 'Invalid identification_status' };
    identification_status = parsed.value;
  }
  if (neuterRaw !== undefined) {
    const parsed = parseProfileFactStatus(neuterRaw);
    if (!parsed.ok) return { ok: false, error: 'Invalid neuter_status' };
    neuter_status = parsed.value;
  }
  const chipId = body.chipId ?? body.chip_id ?? '';
  const neuteredDate = body.neuteredDate ?? body.neutered_date ?? null;
  const merged = {
    identification_status,
    neuter_status,
    chip_id: chipId == null ? '' : String(chipId),
    chip_dismissed: Boolean(body.chipDismissed ?? body.chip_dismissed ?? false),
    neuter_dismissed: Boolean(body.neuterDismissed ?? body.neuter_dismissed ?? false),
    identification_status_source: bodyValue(body, 'identificationStatusSource', 'identification_status_source') ?? null,
    neuter_status_source: bodyValue(body, 'neuterStatusSource', 'neuter_status_source') ?? null,
    identification_status_updated_at: null,
    neuter_status_updated_at: null,
  };
  const norm = normaliseProfileFacts(merged, neuteredDate);
  if (!norm.ok) return norm;
  return { ok: true, patch: norm.patch };
}

export { STATUS_KEYS };
