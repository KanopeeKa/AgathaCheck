import {
  CHANGE_THRESHOLDS,
  evaluateWeightChangeSpec,
} from '../../routes/careIntelligence/weightChangeSpec.js';

describe('weightChangeSpec', () => {
  const measurements = [
    { date: '2026-01-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
    { date: '2026-02-01', weight: 4.8, unit: 'kg', measurement_source: 'guardian' },
    { date: '2026-03-01', weight: 4.5, unit: 'kg', measurement_source: 'guardian' },
  ];

  it('returns insufficient_data when below minimum measurements', () => {
    const result = evaluateWeightChangeSpec(measurements.slice(0, 1), {
      management_context: 'none',
    });
    expect(result.classification).toBe('insufficient_data');
  });

  it('classifies active management context as explained without inferring from measurements', () => {
    const result = evaluateWeightChangeSpec(measurements, {
      management_context: 'vet_managed',
      reference_authority: null,
      reference_value: null,
    });
    expect(result.classification).toBe('explained');
    expect(result.reasons).toContain('management_context:vet_managed');
  });
});

describe('weightChangeSpec classification branches', () => {
  const noContext = { management_context: 'none', reference_authority: null, reference_value: null };
  const adultPet = { date_of_birth: '2018-01-01' };

  // Persistent decline across the last 3 measurements, ~10% drop.
  const persistentDecline = [
    { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
    { date: '2026-01-20', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
    { date: '2026-02-10', weight: 5.3, unit: 'kg', measurement_source: 'guardian' },
    { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
  ];

  it('classifies change below material threshold as ordinary', () => {
    // ~1.5% over 3 points: below MATERIAL_PCT (5%) and abs delta below 0.3kg.
    const small = [
      { date: '2026-01-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-01', weight: 4.95, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 4.92, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(small, noContext, adultPet);
    expect(result.classification).toBe('ordinary');
    expect(result.reasons).toContain('change_below_material_threshold');
    expect(result.persistent).toBe(false);
  });

  it('classifies puppy growth as ordinary life-stage', () => {
    const puppy = { date_of_birth: '2025-09-01' };
    // asOf pinned to the last measurement; puppy <12 months, direction up.
    const growth = [
      { date: '2026-01-01', weight: 8.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 8.5, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 9.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 9.4, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(growth, noContext, puppy, '2026-03-01');
    expect(result.classification).toBe('ordinary');
    expect(result.direction).toBe('up');
    expect(result.persistent).toBe(true);
    expect(result.reasons).toContain('life_stage_growth');
  });

  it('does not treat puppy weight LOSS as life-stage ordinary', () => {
    const puppy = { date_of_birth: '2025-09-01' };
    const decline = [
      { date: '2026-01-01', weight: 9.4, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 9.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 8.5, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 8.0, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(decline, noContext, puppy, '2026-03-01');
    expect(result.classification).toBe('unexplained_material');
    expect(result.direction).toBe('down');
  });

  it('classifies reference-authority within tolerance as explained', () => {
    // Last weight 5.0, reference 5.0 → 0% diff, within REFERENCE_TOLERANCE_PCT.
    const stable = [
      { date: '2026-01-01', weight: 5.2, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-01', weight: 5.1, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(stable, {
      management_context: 'none',
      reference_authority: 'vet_target',
      reference_value: 5.0,
    }, adultPet);
    expect(result.classification).toBe('explained');
    expect(result.reasons).toContain('reference_authority:vet_target');
  });

  it('does not suppress via reference authority when outside tolerance', () => {
    // Last weight 5.0 vs reference 6.0 → ~16.7% diff, well outside 5% tolerance.
    const result = evaluateWeightChangeSpec(persistentDecline, {
      management_context: 'none',
      reference_authority: 'vet_target',
      reference_value: 6.0,
    }, adultPet);
    expect(result.classification).toBe('unexplained_material');
  });

  it('classifies material but non-persistent change as ordinary (not_persistent)', () => {
    // Material drop then rebound: direction 'down' but last-3 not monotonic.
    const nonPersistent = [
      { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 5.4, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 5.5, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(nonPersistent, noContext, adultPet);
    expect(result.classification).toBe('ordinary');
    expect(result.reasons).toContain('not_persistent');
    expect(result.persistent).toBe(false);
  });

  it('classifies a material but non-monotonic change within the ordinary band as ordinary (short_term_fluctuation)', () => {
    // |delta_pct| = 5.5%: above MATERIAL_PCT (5%) and below ORDINARY_FLUCTUATION_PCT*2 (6%),
    // with a non-monotonic last-3 tail → short_term_fluctuation.
    const fluctuation = [
      { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 5.8, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 5.9, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 5.67, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(fluctuation, noContext, adultPet);
    expect(result.classification).toBe('ordinary');
    expect(result.reasons[0]).toBe('short_term_fluctuation');
    expect(result.persistent).toBe(false);
  });

  it('treats a clearly material persistent decline as unexplained_material', () => {
    // ~16.7% monotonic decline, well above MATERIAL_PCT, tail monotonic.
    const result = evaluateWeightChangeSpec(persistentDecline, noContext, adultPet);
    expect(result.classification).toBe('unexplained_material');
    expect(result.direction).toBe('down');
    expect(result.persistent).toBe(true);
    expect(result.reasons).toContain('material_persistent_change');
  });

  it('float edge: a change that is exactly 0.3 kg / ~5% can fall just below the material threshold due to IEEE-754', () => {
    // 6.0 -> 5.85 -> 5.7: deltaKg computes to ~-0.2999999999999998 and delta_pct
    // to ~-0.04999999999999982, so |delta_pct| < MATERIAL_PCT and |deltaKg| <
    // MATERIAL_ABSOLUTE_KG → classified ordinary, not material. This pins the
    // current (tolerant) boundary behaviour; a future threshold tightening should
    // revisit this.
    const atBoundary = [
      { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 5.85, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(atBoundary, noContext, adultPet);
    expect(result.classification).toBe('ordinary');
    expect(result.reasons).toContain('change_below_material_threshold');
  });

  it('reports null direction for flat series', () => {
    const flat = [
      { date: '2026-01-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-01', weight: 5.01, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(flat, noContext, adultPet);
    expect(result.direction).toBe('flat');
    expect(result.classification).toBe('ordinary');
  });

  it('uses the last measurement date as evaluationDate when asOf is omitted', () => {
    // Puppy born 2025-09-01; last measurement 2026-03-01 → ~6 months (under 12).
    // A monotonic up series at that age is life-stage ordinary.
    const growth = [
      { date: '2026-01-01', weight: 8.0, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-01-20', weight: 8.6, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-02-10', weight: 9.2, unit: 'kg', measurement_source: 'guardian' },
      { date: '2026-03-01', weight: 9.8, unit: 'kg', measurement_source: 'guardian' },
    ];
    const result = evaluateWeightChangeSpec(growth, noContext, { date_of_birth: '2025-09-01' });
    expect(result.classification).toBe('ordinary');
    expect(result.reasons).toContain('life_stage_growth');
  });

  it('exposes the configured thresholds used by the boundaries', () => {
    expect(CHANGE_THRESHOLDS.MATERIAL_PCT).toBe(0.05);
    expect(CHANGE_THRESHOLDS.ORDINARY_FLUCTUATION_PCT).toBe(0.03);
    expect(CHANGE_THRESHOLDS.MIN_MEASUREMENTS).toBe(3);
    expect(CHANGE_THRESHOLDS.REFERENCE_TOLERANCE_PCT).toBe(0.05);
  });
});
