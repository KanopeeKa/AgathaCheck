import { resolvePlannedAbsenceTodayIso } from '../../lib/care/plannedAbsence.js';

describe('resolvePlannedAbsenceTodayIso', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  it('uses declarer account timezone, not UTC midnight rollover', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-10-09T02:30:00.000Z'));

    const pool = {
      query: async () => ({ rows: [{ timezone: 'America/Los_Angeles' }] }),
    };

    expect(await resolvePlannedAbsenceTodayIso(pool, 'user-1')).toBe('2026-10-08');
  });

  it('falls back to UTC when account timezone is missing', async () => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-10-08T12:00:00.000Z'));

    const pool = {
      query: async () => ({ rows: [{ timezone: null }] }),
    };

    expect(await resolvePlannedAbsenceTodayIso(pool, 'user-1')).toBe('2026-10-08');
  });
});
