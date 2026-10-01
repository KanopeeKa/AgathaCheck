import { describe, expect, it } from '@jest/globals';

import { addCalendarDaysIso } from '../lib/calendarDate.js';
import {
  isOccurrenceMissed,
  normalizeTime,
  scheduleTimesFromEntry,
} from '../lib/occurrenceScheduling.js';
import {
  isEntrySeriesClosed,
  isOccurrenceDateWithinSeries,
} from '../lib/occurrenceLifecycle.js';

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

  it('isEntrySeriesClosed uses status and repeat end date', () => {
    expect(isEntrySeriesClosed({ status: 'completed', frequency: 'daily' })).toBe(true);
    expect(isEntrySeriesClosed({
      frequency: 'daily',
      repeat_end_date: new Date('2026-09-01'),
    }, '2026-09-02')).toBe(true);
    expect(isEntrySeriesClosed({
      frequency: 'daily',
      repeat_end_date: new Date('2026-09-02'),
    }, '2026-09-02')).toBe(false);
    expect(isOccurrenceDateWithinSeries({
      repeat_end_date: new Date('2026-09-30'),
    }, '2026-10-01')).toBe(false);
  });
});
