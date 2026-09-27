import { describe, expect, it } from '@jest/globals';

import {
  clientTimezoneFromRequest,
  isValidIanaTimeZone,
  normalizePetHomeTimezone,
  resolveDefaultHomeTimezoneForCreate,
  wallClockInTimeZone,
} from '../lib/petHomeTimezone.js';

describe('petHomeTimezone', () => {
  it('validates IANA zones', () => {
    expect(isValidIanaTimeZone('Europe/Paris')).toBe(true);
    expect(isValidIanaTimeZone('Not/AZone')).toBe(false);
    expect(isValidIanaTimeZone('')).toBe(false);
  });

  it('normalizes invalid values to fallback', () => {
    expect(normalizePetHomeTimezone('Europe/Paris')).toBe('Europe/Paris');
    expect(normalizePetHomeTimezone('bogus', 'UTC')).toBe('UTC');
  });

  it('wallClockInTimeZone returns YYYY-MM-DD and HH:MM', () => {
    const instant = new Date('2026-09-02T15:30:00.000Z');
    const paris = wallClockInTimeZone('Europe/Paris', instant);
    expect(paris.todayIso).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(paris.nowTimeIso).toMatch(/^\d{2}:\d{2}$/);
  });

  it('resolveDefaultHomeTimezoneForCreate prefers body then header', () => {
    const withBody = resolveDefaultHomeTimezoneForCreate({
      body: { homeTimezone: 'America/New_York' },
      headers: { 'x-client-timezone': 'Europe/London' },
    });
    expect(withBody).toBe('America/New_York');

    const withHeader = resolveDefaultHomeTimezoneForCreate({
      body: {},
      headers: { 'x-client-timezone': 'Europe/London' },
    });
    expect(withHeader).toBe('Europe/London');
  });

  it('clientTimezoneFromRequest reads header case-insensitively', () => {
    expect(clientTimezoneFromRequest({
      headers: { 'x-client-timezone': 'Pacific/Auckland' },
    })).toBe('Pacific/Auckland');
  });
});
