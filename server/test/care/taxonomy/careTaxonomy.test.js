import { describe, expect, it } from '@jest/globals';
import {
  defaultsForCareFamily,
  deriveLegacyHealthEntryType,
  filterGroupForCareFamily,
  loadCareTaxonomy,
} from '../../../lib/care/taxonomy/index.js';

describe('care taxonomy', () => {
  it('loads shared JSON with all nine families', () => {
    const taxonomy = loadCareTaxonomy();
    expect(taxonomy.version).toBe(1);
    expect(Object.keys(taxonomy.families).sort()).toEqual([
      'dental',
      'grooming',
      'medication',
      'nail_care',
      'other',
      'parasite_prevention',
      'vaccination',
      'weight_monitoring',
      'wellness_review',
    ]);
  });

  it('derives legacy type from family and setting', () => {
    expect(deriveLegacyHealthEntryType('medication', 'home')).toBe('medication');
    expect(deriveLegacyHealthEntryType('vaccination', 'vet')).toBe('preventive');
    expect(deriveLegacyHealthEntryType('wellness_review', 'vet')).toBe('vet_visit');
    expect(deriveLegacyHealthEntryType('grooming', 'other')).toBe('other');
    expect(deriveLegacyHealthEntryType(null, 'home')).toBe('other');
  });

  it('returns family defaults and null-family fallbacks', () => {
    expect(defaultsForCareFamily('vaccination')).toEqual({
      care_setting: 'vet',
      care_importance: 'essential',
    });
    expect(defaultsForCareFamily(null)).toEqual({
      care_setting: 'other',
      care_importance: 'optional',
    });
  });

  it('exposes filter groups for chip UI', () => {
    expect(filterGroupForCareFamily('parasite_prevention')).toBe('prevention');
    expect(filterGroupForCareFamily('dental')).toBe('clinical');
    expect(filterGroupForCareFamily('grooming')).toBe('lifestyle');
  });
});
