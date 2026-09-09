import {
  isWeightMonitoringEntry,
  parseWeightObservationBody,
  weightPayloadsSemanticallyEqual,
} from '../../routes/healthEntries/weightOccurrenceCompletion.js';

describe('weightOccurrenceCompletion helpers', () => {
  describe('isWeightMonitoringEntry', () => {
    it('returns true for weight_monitoring care family', () => {
      expect(isWeightMonitoringEntry({ care_family: 'weight_monitoring' })).toBe(true);
    });

    it('returns false for other families', () => {
      expect(isWeightMonitoringEntry({ care_family: 'dental' })).toBe(false);
      expect(isWeightMonitoringEntry(null)).toBe(false);
    });
  });

  describe('parseWeightObservationBody', () => {
    it('parses a valid payload', () => {
      const result = parseWeightObservationBody({
        weight: 18.2,
        unit: 'kg',
        date: '2026-09-09',
        measurement_source: 'guardian',
        notes: ' morning ',
      });
      expect(result.error).toBeUndefined();
      expect(result.value).toEqual({
        weight: 18.2,
        unit: 'kg',
        date: '2026-09-09',
        measurement_source: 'guardian',
        notes: 'morning',
      });
    });

    it('rejects missing weight', () => {
      expect(parseWeightObservationBody({}).error).toBe('weight is required');
    });
  });

  describe('weightPayloadsSemanticallyEqual', () => {
    const base = {
      weight: 18.2,
      unit: 'kg',
      date: '2026-09-09',
      measurement_source: 'guardian',
      notes: '',
    };

    it('matches identical payloads', () => {
      expect(weightPayloadsSemanticallyEqual(base, { ...base })).toBe(true);
    });

    it('detects material weight difference', () => {
      expect(weightPayloadsSemanticallyEqual(base, { ...base, weight: 19 })).toBe(false);
    });

    it('detects material date difference', () => {
      expect(weightPayloadsSemanticallyEqual(base, { ...base, date: '2026-09-10' })).toBe(false);
    });
  });
});
