import { loadCareTaxonomy } from './loadTaxonomy.js';

export { loadCareTaxonomy, resetCareTaxonomyCache } from './loadTaxonomy.js';

/**
 * @param {string|null|undefined} careFamily
 * @param {string|null|undefined} careSetting
 * @returns {string}
 */
export function deriveLegacyHealthEntryType(careFamily, careSetting) {
  const taxonomy = loadCareTaxonomy();
  const family = careFamily == null || careFamily === '' ? null : String(careFamily);
  const setting = normalizeCareSetting(careSetting, taxonomy);

  if (!family) {
    return 'other';
  }

  const definition = taxonomy.families[family];
  if (!definition) {
    return 'other';
  }

  return definition.derived_legacy_type[setting] ?? 'other';
}

/**
 * @param {string|null|undefined} careFamily
 * @returns {{ care_setting: string, care_importance: string }}
 */
export function defaultsForCareFamily(careFamily) {
  const taxonomy = loadCareTaxonomy();
  const family = careFamily == null || careFamily === '' ? null : String(careFamily);

  if (!family) {
    return {
      care_setting: taxonomy.null_family_defaults.care_setting,
      care_importance: taxonomy.null_family_defaults.care_importance,
    };
  }

  const definition = taxonomy.families[family];
  if (!definition) {
    return {
      care_setting: taxonomy.null_family_defaults.care_setting,
      care_importance: taxonomy.null_family_defaults.care_importance,
    };
  }

  return {
    care_setting: definition.default_setting,
    care_importance: definition.default_importance,
  };
}

/**
 * @param {string|null|undefined} value
 * @param {ReturnType<typeof loadCareTaxonomy>} taxonomy
 * @returns {string}
 */
function normalizeCareSetting(value, taxonomy) {
  const raw = value == null || value === '' ? null : String(value);
  if (raw && taxonomy.care_settings.includes(raw)) {
    return raw;
  }
  return taxonomy.null_family_defaults.care_setting;
}

/**
 * @param {string|null|undefined} careFamily
 * @returns {string|null}
 */
export function filterGroupForCareFamily(careFamily) {
  const taxonomy = loadCareTaxonomy();
  if (!careFamily) return null;
  const definition = taxonomy.families[String(careFamily)];
  return definition?.filter_group ?? null;
}
