import { evaluateS2WeightTrend } from '../../lib/suggestions/s2WeightTrend.js';

describe('evaluateS2WeightTrend', () => {
  const pet = { id: 'p1', name: 'Luna', passed_away: false };

  it('detects upward trend above threshold', () => {
    const now = new Date('2026-10-01');
    const entries = [
      { weight: 5.4, date: '2026-09-15' },
      { weight: 5.0, date: '2026-08-01' },
    ];
    const result = evaluateS2WeightTrend(pet, entries, now);
    expect(result).not.toBeNull();
    expect(result.wireType).toBe('suggestionWeightTrend');
    expect(result.payload.health_adjacent).toBe(true);
    expect(result.title).toMatch(/up 8%/);
  });

  it('returns null when change is below threshold', () => {
    const entries = [
      { weight: 5.1, date: '2026-09-01' },
      { weight: 5.0, date: '2026-06-01' },
    ];
    expect(evaluateS2WeightTrend(pet, entries)).toBeNull();
  });
});
