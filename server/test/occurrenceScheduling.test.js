import { describe, expect, it } from '@jest/globals';

import { addCalendarDaysIso } from '../lib/calendarDate.js';
import {
  initialMaterialisationAnchor,
  isOccurrenceMissed,
  isWithinMaterialisationWindow,
  materialisationAnchor,
  normalizeTime,
  scheduleTimesFromEntry,
} from '../lib/occurrenceScheduling.js';

describe('occurrenceScheduling helpers', () => {
  it('scheduleTimesFromEntry returns [null] for all-day', () => {
    expect(scheduleTimesFromEntry({})).toEqual([null]);
    expect(scheduleTimesFromEntry({ schedule_times: null })).toEqual([null]);
    expect(scheduleTimesFromEntry({ schedule_times: [] })).toEqual([null]);
  });

  it('scheduleTimesFromEntry normalizes timed slots', () => {
    expect(scheduleTimesFromEntry({ schedule_times: ['8:00', '18:30'] })).toEqual([
      '08:00',
      '18:30',
    ]);
  });

  it('materialisationAnchor uses max(start, today)', () => {
    expect(materialisationAnchor('2026-08-01', '2026-09-02')).toBe('2026-09-02');
    expect(materialisationAnchor('2026-10-01', '2026-09-02')).toBe('2026-10-01');
  });

  it('initialMaterialisationAnchor preserves overdue next_due_date', () => {
    expect(initialMaterialisationAnchor(null, '2026-08-26', '2026-09-02')).toBe('2026-08-26');
    expect(initialMaterialisationAnchor('2026-08-01', '2026-08-26', '2026-09-02')).toBe('2026-08-26');
    expect(initialMaterialisationAnchor(null, '2026-09-05', '2026-09-02')).toBeNull();
    expect(initialMaterialisationAnchor(null, '2026-09-03', '2026-09-02')).toBe('2026-09-03');
    expect(initialMaterialisationAnchor(null, null, '2026-09-02')).toBe('2026-09-02');
  });

  it('isWithinMaterialisationWindow is calendar T-1', () => {
    expect(isWithinMaterialisationWindow('2026-09-03', '2026-09-02')).toBe(true);
    expect(isWithinMaterialisationWindow('2026-09-03', '2026-09-01')).toBe(false);
  });

  it('isOccurrenceMissed handles all-day and timed', () => {
    expect(isOccurrenceMissed('2026-09-01', null, '2026-09-02', '10:00')).toBe(true);
    expect(isOccurrenceMissed('2026-09-02', null, '2026-09-02', '10:00')).toBe(false);
    expect(isOccurrenceMissed('2026-09-02', '08:00', '2026-09-02', '09:00')).toBe(true);
    expect(isOccurrenceMissed('2026-09-02', '18:00', '2026-09-02', '09:00')).toBe(false);
  });

  it('normalizeTime pads hours', () => {
    expect(normalizeTime('8:05')).toBe('08:05');
  });

  it('addCalendarDaysIso shifts calendar days', () => {
    expect(addCalendarDaysIso('2026-09-02', 1)).toBe('2026-09-03');
    expect(addCalendarDaysIso('2026-09-02', -1)).toBe('2026-09-01');
  });
});
