import {
  CADENCE_BAND_REQUIREMENTS,
  evaluateWeightEstablishment,
  resolveCadenceBand,
  WEIGHT_ESTABLISHMENT_POLICY_VERSION,
} from '../../../lib/care/progression/weightEstablishmentPolicy.js';

const petId = 'pet-1';
const healthEntryId = 'he-weight';

function makeEntry(overrides = {}) {
  return {
    id: healthEntryId,
    pet_id: petId,
    care_family: 'weight_monitoring',
    status: 'active',
    frequency: 'weekly',
    frequency_interval: 1,
    ...overrides,
  };
}

function makeEvidence(dates) {
  return dates.map((date, index) => ({
    occurrenceId: `occ-${index}`,
    completedOn: date,
    measurement: { date, weight: 10 + index, unit: 'kg' },
  }));
}

describe('weightEstablishmentPolicy', () => {
  it('records policy version on every evaluation', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, { entry: makeEntry() });
    expect(result.policyVersion).toBe(WEIGHT_ESTABLISHMENT_POLICY_VERSION);
  });

  it('returns established for eligible weekly rhythm with enough linked evidence', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'weekly', frequency_interval: 1 }),
      completedEvidence: makeEvidence([
        '2026-06-01',
        '2026-06-08',
        '2026-06-15',
        '2026-06-22',
      ]),
    });
    expect(result.maturity).toBe('established');
    expect(result.reasonCodes).toContain('established');
  });

  it('returns accumulating_evidence when not yet eligible', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'weekly', frequency_interval: 1 }),
      completedEvidence: makeEvidence(['2026-06-01', '2026-06-08']),
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('accumulating_evidence');
  });

  it('returns insufficient_evidence when no linked completions exist', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry(),
      completedEvidence: [],
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('insufficient_evidence');
  });

  it('silences ambiguous family entries', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ care_family: 'other' }),
      completedEvidence: makeEvidence([
        '2026-06-01',
        '2026-06-08',
        '2026-06-15',
        '2026-06-22',
      ]),
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('ambiguous_family');
  });

  it('excludes skipped occurrences from eligibility', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'weekly', frequency_interval: 1 }),
      completedEvidence: makeEvidence(['2026-06-01', '2026-06-08', '2026-06-15']),
      skippedCount: 3,
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('skipped_occurrences_excluded');
    expect(result.reasonCodes).toContain('accumulating_evidence');
  });

  it('ignores legacy mark-taken completions without linked weight', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'weekly', frequency_interval: 1 }),
      completedEvidence: makeEvidence(['2026-06-01', '2026-06-08', '2026-06-15']),
      legacyCompletedWithoutWeight: 2,
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('legacy_completion_ignored');
    expect(result.reasonCodes).toContain('accumulating_evidence');
  });

  it('does not re-establish when a row already exists', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry(),
      existingEstablishment: { id: 'est-1' },
      completedEvidence: makeEvidence([
        '2026-06-01',
        '2026-06-08',
        '2026-06-15',
        '2026-06-22',
      ]),
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('already_established');
  });

  it('defers low-frequency annual rhythms in V1', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'yearly', frequency_interval: 1 }),
      completedEvidence: makeEvidence(['2026-01-01', '2027-01-01', '2028-01-01']),
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('not_evaluable');
  });

  it('resolves cadence bands for weekly and monthly rhythms', () => {
    expect(resolveCadenceBand({ frequency: 'weekly', frequency_interval: 1 })).toBe('high');
    expect(resolveCadenceBand({ frequency: 'weekly', frequency_interval: 2 })).toBe('high');
    expect(resolveCadenceBand({ frequency: 'monthly', frequency_interval: 1 })).toBe('medium');
    expect(resolveCadenceBand({ frequency: 'yearly', frequency_interval: 1 })).toBe('low_deferred');
  });

  it('requires medium-band span for monthly rhythms', () => {
    const result = evaluateWeightEstablishment(petId, healthEntryId, {
      entry: makeEntry({ frequency: 'monthly', frequency_interval: 1 }),
      completedEvidence: makeEvidence(['2026-06-01', '2026-06-15', '2026-07-01']),
    });
    expect(result.maturity).toBeNull();
    expect(result.reasonCodes).toContain('accumulating_evidence');
    expect(CADENCE_BAND_REQUIREMENTS.medium.minSpanDays).toBeGreaterThan(30);
  });
});
