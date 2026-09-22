import {
  rejectClientTypeField,
  resolveClassificationForWrite,
} from '../../../lib/care/taxonomy/classification.js';

describe('care taxonomy classification', () => {
  describe('rejectClientTypeField', () => {
    it('allows requests without type', () => {
      expect(rejectClientTypeField({ care_family: 'medication' })).toEqual({ ok: true });
    });

    it('rejects client-sent type', () => {
      const result = rejectClientTypeField({ type: 'medication', care_family: 'medication' });
      expect(result.ok).toBe(false);
      expect(result.error).toMatch(/server-derived/i);
    });
  });

  describe('resolveClassificationForWrite', () => {
    it('derives legacy type from family and default setting', () => {
      const result = resolveClassificationForWrite({
        data: {},
        careFamily: 'parasite_prevention',
        frequency: 'monthly',
        completedOn: null,
        nextDueDate: '2026-01-01',
      });
      expect(result.ok).toBe(true);
      expect(result.value).toMatchObject({
        care_setting: 'home',
        care_planning: 'planned',
        care_importance: 'essential',
        type: 'preventive',
      });
    });

    it('rejects unplanned recurring entries', () => {
      const result = resolveClassificationForWrite({
        data: { care_planning: 'unplanned' },
        careFamily: 'grooming',
        frequency: 'weekly',
        completedOn: '2026-01-01',
        nextDueDate: null,
      });
      expect(result.ok).toBe(false);
      expect(result.error).toMatch(/unplanned entries cannot recur/i);
    });

    it('requires completed_on for unplanned entries', () => {
      const result = resolveClassificationForWrite({
        data: { care_planning: 'unplanned' },
        careFamily: 'wellness_review',
        frequency: 'once',
        completedOn: null,
        nextDueDate: null,
      });
      expect(result.ok).toBe(false);
      expect(result.error).toMatch(/completed_on is required/i);
    });
  });
});
