import { dateToIsoDate, normalizeCalendarDateInput, todayCalendarIso } from '../lib/calendarDate.js';
import { advanceByFrequency, nextOccurrence, toDateOnly } from '../lib/recurrenceHelper.js';

describe('dateToIsoDate', () => {
  it('returns YYYY-MM-DD for a Date at UTC midnight', () => {
    expect(dateToIsoDate(new Date('2026-06-30T00:00:00.000Z'))).toBe('2026-06-30');
  });

  it('returns YYYY-MM-DD for a date-only string', () => {
    expect(dateToIsoDate('2026-06-30')).toBe('2026-06-30');
  });

  it('extracts the date portion from legacy ISO timestamps', () => {
    expect(dateToIsoDate('2026-06-30T09:00:00.000Z')).toBe('2026-06-30');
  });

  it('extracts the date portion from space-separated timestamps', () => {
    expect(dateToIsoDate('2026-06-30 00:00:00.000Z')).toBe('2026-06-30');
  });

  it('returns null for null/empty/invalid', () => {
    expect(dateToIsoDate(null)).toBeNull();
    expect(dateToIsoDate('')).toBeNull();
    expect(dateToIsoDate('not-a-date')).toBeNull();
  });
});

describe('normalizeCalendarDateInput', () => {
  it('normalizes date-only request values', () => {
    expect(normalizeCalendarDateInput('2026-07-15')).toBe('2026-07-15');
  });
});

describe('todayCalendarIso', () => {
  it('returns a YYYY-MM-DD string', () => {
    expect(todayCalendarIso()).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});

describe('recurrenceHelper calendar dates', () => {
  it('advances weekly from a date-only base without shifting the day', () => {
    const next = advanceByFrequency('2026-06-30', { frequency: 'weekly', frequency_interval: 1 });
    expect(next).toBe('2026-07-07');
  });

  it('computes next occurrence as YYYY-MM-DD', () => {
    const next = nextOccurrence(
      { frequency: 'monthly', frequency_interval: 1, recurrence_anchor: 'from_completion' },
      '2026-06-30',
    );
    expect(next).toBe('2026-07-30');
  });

  it('reads PostgreSQL UTC midnight dates without off-by-one', () => {
    const parts = toDateOnly(new Date('2026-06-30T00:00:00.000Z'));
    expect(parts.getFullYear()).toBe(2026);
    expect(parts.getMonth()).toBe(5);
    expect(parts.getDate()).toBe(30);
  });
});
