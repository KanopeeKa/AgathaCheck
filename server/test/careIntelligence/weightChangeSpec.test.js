import { evaluateWeightChangeSpec } from '../../routes/careIntelligence/weightChangeSpec.js';

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
