import {
  DEFAULT_TIMEZONE,
  isValidIanaTimezone,
  normalizeTimezoneInput,
  resolveTimezoneOrDefault,
} from '../../lib/timezone.js';

describe('timezone helpers', () => {
  it('accepts IANA zones', () => {
    expect(isValidIanaTimezone('Europe/Paris')).toBe(true);
    expect(normalizeTimezoneInput(' Europe/Paris ')).toBe('Europe/Paris');
  });

  it('rejects invalid zones', () => {
    expect(isValidIanaTimezone('Not/A_Zone')).toBe(false);
    expect(normalizeTimezoneInput('bad')).toBeNull();
  });

  it('defaults to UTC', () => {
    expect(resolveTimezoneOrDefault(null)).toBe(DEFAULT_TIMEZONE);
  });
});
