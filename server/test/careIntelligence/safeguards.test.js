import { evaluateWeightSafeguard } from '../../routes/careIntelligence/weightSafeguardEvaluator.js';
import { safeguardToMap } from '../../routes/careIntelligence/safeguardsService.js';

const decliningSeries = [
  { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-01-20', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-02-10', weight: 5.3, unit: 'kg', measurement_source: 'guardian' },
  { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
];

describe('weightSafeguardEvaluator', () => {
  it('surfaces weight trend down safeguard when review relevant', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries,
      weightContext: {
        management_context: 'none',
        reference_authority: null,
        reference_value: null,
      },
    });
    expect(result).not.toBeNull();
    expect(result.safeguard_type).toBe('weight_trend_down');
    expect(result.copy_key).toBe('careSafeguardWeightTrendDown');
  });

  it('does not surface when management context explains change', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries,
      weightContext: {
        management_context: 'vet_managed',
        reference_authority: 'vet_target',
        reference_value: 5.0,
      },
    });
    expect(result).toBeNull();
  });

  it('does not surface with insufficient measurements', () => {
    const result = evaluateWeightSafeguard({
      pet: { id: 'pet-1', date_of_birth: '2018-01-01' },
      measurements: decliningSeries.slice(0, 1),
      weightContext: { management_context: 'none' },
    });
    expect(result).toBeNull();
  });
});

describe('safeguardToMap', () => {
  it('maps row to API shape', () => {
    const mapped = safeguardToMap({
      id: 'sg-1',
      pet_id: 'pet-1',
      safeguard_type: 'weight_trend_down',
      safeguard_key: 'weight_trend_down:pet-1',
      status: 'active',
      policy_version: '1.0.0',
      copy_key: 'careSafeguardWeightTrendDown',
      evidence_json: { measurement_count: 4 },
      dismissed_at: null,
      created_at: '2026-09-09T00:00:00Z',
      updated_at: '2026-09-09T00:00:00Z',
    });
    expect(mapped.evidence.measurement_count).toBe(4);
    expect(mapped.status).toBe('active');
  });
});
