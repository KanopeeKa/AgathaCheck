import {
  daysBetween,
  dedupeWeightMeasurementsByDate,
  hasConsistentWeightUnits,
  isValidWeightMeasurementShape,
  isValidWeightTimestamp,
  median,
  parseDateMs,
  prepareWeightMeasurements,
  stdDev,
} from '../../lib/care/observations/weightPrimitives.js';

describe('weightPrimitives', () => {
  it('parses calendar dates as UTC midnight', () => {
    expect(parseDateMs('2026-01-01')).toBe(Date.parse('2026-01-01T00:00:00Z'));
  });

  it('computes inclusive day span between dates', () => {
    expect(daysBetween('2026-01-01', '2026-01-15')).toBe(14);
  });

  it('validates measurement shape and timestamps', () => {
    expect(isValidWeightTimestamp('2026-01-01')).toBe(true);
    expect(isValidWeightTimestamp('not-a-date')).toBe(false);
    expect(isValidWeightMeasurementShape({ date: '2026-01-01', weight: 4.5 })).toBe(true);
    expect(isValidWeightMeasurementShape({ date: '2026-01-01', weight: -1 })).toBe(false);
  });

  it('detects mixed units', () => {
    expect(hasConsistentWeightUnits([
      { unit: 'kg', weight: 1, date: '2026-01-01' },
      { unit: 'lb', weight: 2, date: '2026-01-02' },
    ])).toBe(false);
    expect(hasConsistentWeightUnits([
      { weight: 1, date: '2026-01-01' },
      { weight: 2, date: '2026-01-02' },
    ])).toBe(true);
  });

  it('dedupes measurements by date keeping the last entry', () => {
    const result = dedupeWeightMeasurementsByDate([
      { date: '2026-01-01', weight: 5.0 },
      { date: '2026-01-01', weight: 5.2 },
      { date: '2026-01-10', weight: 5.1 },
    ]);
    expect(result).toHaveLength(2);
    expect(result[0].weight).toBe(5.2);
    expect(result[1].weight).toBe(5.1);
  });

  it('prepareWeightMeasurements filters invalid rows then dedupes', () => {
    const result = prepareWeightMeasurements([
      { date: 'bad', weight: 1 },
      { date: '2026-01-01', weight: 4.0 },
      { date: '2026-01-01', weight: 4.1 },
    ]);
    expect(result).toEqual([{ date: '2026-01-01', weight: 4.1 }]);
  });

  it('computes median and standard deviation', () => {
    expect(median([1, 3, 9])).toBe(3);
    expect(stdDev([2, 4, 4, 4, 5, 5, 7, 9], 5)).toBeCloseTo(2, 5);
  });
});
