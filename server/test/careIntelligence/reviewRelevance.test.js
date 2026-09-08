import { classifyWeightSeriesQuality } from '../../routes/careIntelligence/weightQualityClassifier.js';
import { evaluateReviewRelevance } from '../../routes/careIntelligence/reviewRelevance.js';
import { runEvaluationHarness } from '../../routes/careIntelligence/evaluationHarness.js';

describe('weightQualityClassifier', () => {
  const adequateSeries = [
    { date: '2026-01-01', weight: 5.0, unit: 'kg' },
    { date: '2026-01-20', weight: 4.9, unit: 'kg' },
    { date: '2026-02-10', weight: 4.8, unit: 'kg' },
    { date: '2026-03-01', weight: 4.7, unit: 'kg' },
  ];

  it('marks adequate series when thresholds met', () => {
    const result = classifyWeightSeriesQuality(adequateSeries);
    expect(result.adequate).toBe(true);
    expect(result.reasons).toHaveLength(0);
  });

  it('flags sparse series', () => {
    const result = classifyWeightSeriesQuality(adequateSeries.slice(0, 1));
    expect(result.adequate).toBe(false);
    expect(result.reasons).toContain('measurement_count_below_minimum');
  });
});

describe('reviewRelevance', () => {
  it('flags persistent unexplained decline as review relevant', () => {
    const outcome = evaluateReviewRelevance({
      pet: { id: 'p1', date_of_birth: '2018-01-01' },
      measurements: [
        { date: '2026-01-01', weight: 6.0, unit: 'kg', measurement_source: 'guardian' },
        { date: '2026-01-20', weight: 5.7, unit: 'kg', measurement_source: 'guardian' },
        { date: '2026-02-10', weight: 5.3, unit: 'kg', measurement_source: 'guardian' },
        { date: '2026-03-01', weight: 5.0, unit: 'kg', measurement_source: 'guardian' },
      ],
      weightContext: { management_context: 'none', reference_authority: null, reference_value: null },
    });
    expect(outcome.review_relevant).toBe(true);
    expect(outcome.weight_change_spec.classification).toBe('unexplained_material');
  });
});

describe('evaluationHarness', () => {
  it('passes all reference vectors', () => {
    const report = runEvaluationHarness();
    expect(report.failed).toBe(0);
    expect(report.passed).toBeGreaterThan(0);
  });
});
