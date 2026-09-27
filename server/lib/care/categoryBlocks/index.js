/**
 * Care item category blocks (D-CIE-019) — item-level fields only in phase f-categories.
 */

const MAX_TEXT = 500;

/** @typedef {'product_dose' | 'visit'} BlockKey */

/** @type {Record<string, BlockKey[]>} */
export const BLOCKS_BY_CARE_FAMILY = {
  medication: ['product_dose'],
  vaccination: ['visit'],
  weight_monitoring: [],
  parasite_prevention: ['product_dose'],
  wellness_review: ['visit'],
  dental: ['product_dose', 'visit'],
  grooming: [],
  nail_care: [],
  other: [],
};

const PRODUCT_DOSE_KEYS = [
  'product_name',
  'form',
  'strength',
  'dose_amount',
  'dose_unit',
  'route_method',
];

const VISIT_KEYS = ['questions_to_ask'];

function trimOptionalString(value, maxLen = MAX_TEXT) {
  if (value === null || value === undefined) return null;
  const s = String(value).trim();
  if (!s) return null;
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}

function emptyObject(obj) {
  return !obj || typeof obj !== 'object' || Object.keys(obj).length === 0;
}

function parseProductDose(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const out = {};
  for (const key of PRODUCT_DOSE_KEYS) {
    const v = trimOptionalString(raw[key]);
    if (v) out[key] = v;
  }
  return emptyObject(out) ? null : out;
}

function parseVisit(raw) {
  if (!raw || typeof raw !== 'object') return null;
  const questions = trimOptionalString(raw.questions_to_ask);
  if (!questions) return null;
  return { questions_to_ask: questions };
}

/**
 * @param {unknown} raw
 * @returns {{ product_dose?: object, visit?: object }}
 */
export function parseCareBlocksObject(raw) {
  if (!raw || typeof raw !== 'object') return {};
  const productDose = parseProductDose(raw.product_dose ?? raw.productDose);
  const visit = parseVisit(raw.visit);
  const out = {};
  if (productDose) out.product_dose = productDose;
  if (visit) out.visit = visit;
  return out;
}

/**
 * @param {object} data Request body
 */
export function parseCareBlocksInput(data) {
  const raw = data.care_blocks ?? data.careBlocks;
  if (raw === undefined) return undefined;
  return parseCareBlocksObject(raw);
}

/**
 * Keep only blocks allowed for the care family.
 * @param {object} blocks
 * @param {string} careFamily
 */
export function filterBlocksForFamily(blocks, careFamily) {
  const allowed = new Set(BLOCKS_BY_CARE_FAMILY[careFamily] ?? []);
  const out = {};
  if (allowed.has('product_dose') && blocks.product_dose) {
    out.product_dose = blocks.product_dose;
  }
  if (allowed.has('visit') && blocks.visit) {
    out.visit = blocks.visit;
  }
  return out;
}

/**
 * Legacy dosage → product_dose.dose_amount when block dose empty.
 */
export function enrichBlocksFromLegacyDosage(blocks, dosage) {
  const out = { ...blocks };
  const dose = trimOptionalString(dosage);
  if (!dose) return out;
  const pd = out.product_dose ? { ...out.product_dose } : {};
  const hasDoseField =
    pd.dose_amount || pd.dose_unit;
  if (!hasDoseField && !pd.dose_amount) {
    pd.dose_amount = dose;
    out.product_dose = pd;
  }
  return out;
}

/**
 * Sync legacy `dosage` column from product_dose fields.
 */
export function dosageFromProductDose(blocks, fallbackDosage = '') {
  const pd = blocks?.product_dose;
  if (!pd) return trimOptionalString(fallbackDosage) ?? '';
  const amount = pd.dose_amount ?? '';
  const unit = pd.dose_unit ?? '';
  const combined = [amount, unit].filter(Boolean).join(' ').trim();
  if (combined) return combined;
  return trimOptionalString(fallbackDosage) ?? '';
}

/**
 * @param {object} row DB row with care_blocks + dosage + care_family
 */
export function careBlocksForApi(row) {
  const family = row.care_family ?? 'other';
  let blocks = parseCareBlocksObject(row.care_blocks);
  blocks = enrichBlocksFromLegacyDosage(blocks, row.dosage);
  blocks = filterBlocksForFamily(blocks, family);
  return blocks;
}

/**
 * Resolve blocks + dosage for INSERT/UPDATE.
 * @param {object} opts
 * @param {object} opts.data Request body
 * @param {string} opts.careFamily
 * @param {object|null} opts.existing Existing row on update
 * @param {boolean} opts.careFamilyChanged
 */
export function resolveCareBlocksForWrite({
  data,
  careFamily,
  existing = null,
  careFamilyChanged = false,
}) {
  const parsed = parseCareBlocksInput(data);
  let blocks;
  if (parsed !== undefined) {
    blocks = filterBlocksForFamily(parsed, careFamily);
  } else if (existing) {
    blocks = parseCareBlocksObject(existing.care_blocks);
    if (careFamilyChanged) {
      blocks = filterBlocksForFamily(blocks, careFamily);
    } else {
      blocks = filterBlocksForFamily(blocks, careFamily);
    }
  } else {
    blocks = {};
  }

  const dosageInput = data.dosage !== undefined ? data.dosage : (existing?.dosage ?? '');
  const dosage = dosageFromProductDose(blocks, dosageInput);

  if (
    (BLOCKS_BY_CARE_FAMILY[careFamily] ?? []).includes('product_dose')
    && blocks.product_dose
    && dosage
  ) {
    const pd = { ...blocks.product_dose };
    if (!pd.dose_amount && !pd.dose_unit) {
      pd.dose_amount = trimOptionalString(dosage);
      blocks = { ...blocks, product_dose: pd };
    }
  }

  return {
    careBlocks: blocks,
    dosage,
  };
}
