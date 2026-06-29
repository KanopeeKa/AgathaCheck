import { dateToIsoDate } from '../lib/calendarDate.js';

describe('dateToIsoDate', () => {
  it('returns YYYY-MM-DD for a Date at UTC midnight', () => {
    expect(dateToIsoDate(new Date('2026-06-30T00:00:00.000Z'))).toBe('2026-06-30');
  });

  it('returns YYYY-MM-DD for a date-only string', () => {
    expect(dateToIsoDate('2026-06-30')).toBe('2026-06-30');
  });

  it('returns null for null/empty/invalid', () => {
    expect(dateToIsoDate(null)).toBeNull();
    expect(dateToIsoDate('')).toBeNull();
    expect(dateToIsoDate('not-a-date')).toBeNull();
  });
});
