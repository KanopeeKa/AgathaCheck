import {
  dateRangesOverlap,
  normalizeAbsenceTitleInput,
  validateAbsenceDateWindow,
} from '../../lib/care/plannedAbsence.js';
import { addCalendarDaysIso, todayCalendarIso } from '../../lib/calendarDate.js';

describe('plannedAbsence helpers', () => {
  it('validates inclusive date window', () => {
    const today = todayCalendarIso();
    const start = addCalendarDaysIso(today, 1);
    const end = addCalendarDaysIso(today, 5);
    expect(validateAbsenceDateWindow(start, end)).toEqual({
      ok: true,
      starts_on: start,
      ends_on: end,
    });
  });

  it('rejects ends before starts', () => {
    expect(validateAbsenceDateWindow('2026-08-10', '2026-08-09').ok).toBe(false);
  });

  it('normalizes absence title (trim, empty, max length)', () => {
    expect(normalizeAbsenceTitleInput(undefined)).toEqual({ ok: true, title: undefined });
    expect(normalizeAbsenceTitleInput('  Ski week  ')).toEqual({ ok: true, title: 'Ski week' });
    expect(normalizeAbsenceTitleInput('   ')).toEqual({ ok: true, title: null });
    const long = 'x'.repeat(61);
    expect(normalizeAbsenceTitleInput(long).ok).toBe(false);
  });

  it('detects overlapping inclusive ranges', () => {
    expect(dateRangesOverlap('2026-08-12', '2026-08-19', '2026-08-15', '2026-08-22')).toBe(true);
    expect(dateRangesOverlap('2026-08-12', '2026-08-19', '2026-08-20', '2026-08-25')).toBe(false);
    expect(dateRangesOverlap('2026-08-12', '2026-08-19', '2026-08-12', '2026-08-12')).toBe(true);
  });
});
