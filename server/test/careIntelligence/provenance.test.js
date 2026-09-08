import {
  MEASUREMENT_SOURCES,
  REFERENCE_AUTHORITIES,
  MANAGEMENT_CONTEXTS,
  validateMeasurementSource,
  validateReferenceAuthority,
  validateManagementContext,
  weightContextFromPetRow,
} from '../../routes/careIntelligence/provenance.js';

describe('careIntelligence provenance', () => {
  it('accepts valid measurement_source values', () => {
    expect(MEASUREMENT_SOURCES.has('guardian')).toBe(true);
    for (const value of MEASUREMENT_SOURCES) {
      expect(validateMeasurementSource(value).ok).toBe(true);
    }
  });

  it('rejects invalid measurement_source', () => {
    expect(validateMeasurementSource('vet_instruction').ok).toBe(false);
  });

  it('defaults measurement_source to guardian when omitted', () => {
    expect(validateMeasurementSource(undefined).value).toBe('guardian');
  });

  it('accepts reference authority and management context enums', () => {
    expect(validateReferenceAuthority('vet_target').ok).toBe(true);
    expect(validateManagementContext('vet_managed').ok).toBe(true);
    expect(REFERENCE_AUTHORITIES.has('guardian_reference')).toBe(true);
    expect(MANAGEMENT_CONTEXTS.has('none')).toBe(true);
  });

  it('does not infer weight context from measurement source', () => {
    const row = {
      weight_reference_value: null,
      weight_reference_authority: null,
      weight_management_context: 'none',
    };
    expect(weightContextFromPetRow(row)).toEqual({
      reference_value: null,
      reference_authority: null,
      management_context: 'none',
    });
  });
});
