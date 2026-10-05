/**
 * Care-family capability matrix (code-defined policy, CP-1).
 * @see docs/domains/pet_care/features/care-progression.md
 */

import {
  CARE_FAMILIES,
  SKIP_REASON_CODES,
  WEIGHT_MONITORING_SKIP_NOTE_MAX_LENGTH,
} from './enums.js';

export { SKIP_REASON_CODES, WEIGHT_MONITORING_SKIP_NOTE_MAX_LENGTH };

/** @typedef {'core' | 'optional_catalog' | 'device_backed' | 'partner_import'} EntitlementClass */

/**
 * @typedef {object} CareFamilyCapabilities
 * @property {boolean} supportsCareEvents
 * @property {boolean} supportsRecurrence
 * @property {boolean} supportsObservations
 * @property {string | null} observationKind
 * @property {boolean} supportsTrendView
 * @property {boolean} supportsEstablishment
 * @property {boolean} supportsMilestones
 * @property {readonly string[]} speciesApplicability
 * @property {EntitlementClass} entitlementClass
 */

/** @type {Record<string, CareFamilyCapabilities>} */
const CAPABILITY_MATRIX = {
  weight_monitoring: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: true,
    observationKind: 'numeric_weight',
    supportsTrendView: true,
    supportsEstablishment: true,
    supportsMilestones: true,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  medication: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  vaccination: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  parasite_prevention: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  wellness_review: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  dental: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
  grooming: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'optional_catalog',
  },
  nail_care: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'optional_catalog',
  },
  other: {
    supportsCareEvents: true,
    supportsRecurrence: true,
    supportsObservations: false,
    observationKind: null,
    supportsTrendView: false,
    supportsEstablishment: false,
    supportsMilestones: false,
    speciesApplicability: ['dog', 'cat'],
    entitlementClass: 'core',
  },
};

export class CareFamilyCapabilityPolicy {
  static getCapabilities(careFamily) {
    return CAPABILITY_MATRIX[careFamily] ?? null;
  }

  static listFamilies() {
    return [...CARE_FAMILIES];
  }

  static supportsEstablishment(careFamily) {
    return CareFamilyCapabilityPolicy.getCapabilities(careFamily)?.supportsEstablishment === true;
  }

  static supportsMilestones(careFamily) {
    return CareFamilyCapabilityPolicy.getCapabilities(careFamily)?.supportsMilestones === true;
  }

  static supportsProgressionRead() {
    return CareFamilyCapabilityPolicy.listFamilies().some(
      (family) => CareFamilyCapabilityPolicy.supportsEstablishment(family)
        || CareFamilyCapabilityPolicy.supportsMilestones(family),
    );
  }

  static speciesSupportsFamily(careFamily, species) {
    const caps = CareFamilyCapabilityPolicy.getCapabilities(careFamily);
    if (!caps) return false;
    const normalized = String(species || '').toLowerCase();
    return caps.speciesApplicability.includes(normalized);
  }
}

/**
 * @param {string} careFamily
 * @param {string|null|undefined} reasonCode
 * @param {string|null|undefined} notes
 * @returns {{ ok: true } | { ok: false, status: number, body: object }}
 */
export function validateSkipReasonForFamily(careFamily, reasonCode, notes) {
  const allowed = SKIP_REASON_CODES[careFamily];
  if (!allowed || !reasonCode) {
    return { ok: true };
  }
  if (!allowed.includes(reasonCode)) {
    return {
      ok: false,
      status: 400,
      body: { error: 'invalid skip reason', code: 'invalid_skip_reason' },
    };
  }
  if (notes && String(notes).length > WEIGHT_MONITORING_SKIP_NOTE_MAX_LENGTH) {
    return {
      ok: false,
      status: 400,
      body: { error: 'skip note too long', code: 'skip_note_too_long' },
    };
  }
  return { ok: true };
}

export { CAPABILITY_MATRIX };
