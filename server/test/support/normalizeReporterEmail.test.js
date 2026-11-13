import { normalizeSupportReporterEmail } from '../../lib/support/submit/normalizeReporterEmail.js';

describe('normalizeSupportReporterEmail', () => {
  it('lowercases and strips +tag', () => {
    expect(normalizeSupportReporterEmail('  User+tag@Example.COM ')).toBe('user@example.com');
  });

  it('keeps dots in the local part', () => {
    expect(normalizeSupportReporterEmail('first.last@example.com')).toBe('first.last@example.com');
  });
});
