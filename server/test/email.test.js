import { getPublicHost, getPublicUrl } from '../lib/email/branding.js';
import { formatEmailString, getEmailStrings } from '../lib/email/i18n.js';
import {
  normalizeLocale,
  parseAcceptLanguage,
  resolveEmailLocale,
} from '../lib/email/locale.js';
import { renderEmailLayout } from '../lib/email/layout.js';
import { buildPasswordResetEmail } from '../lib/email/templates/passwordReset.js';

describe('email locale', () => {
  it('normalizes supported locales', () => {
    expect(normalizeLocale('fr')).toBe('fr');
    expect(normalizeLocale('fr-FR')).toBe('fr');
    expect(normalizeLocale('en')).toBe('en');
    expect(normalizeLocale('en-US')).toBe('en');
  });

  it('falls back to English for unsupported locales', () => {
    expect(normalizeLocale('de')).toBe('en');
    expect(normalizeLocale('')).toBe('en');
  });

  it('parses Accept-Language headers', () => {
    expect(parseAcceptLanguage('fr-FR,fr;q=0.9,en;q=0.8')).toBe('fr');
    expect(parseAcceptLanguage('en-US,en;q=0.9')).toBe('en');
    expect(parseAcceptLanguage('de-DE,de;q=0.9')).toBe('en');
  });

  it('prefers user locale over Accept-Language', () => {
    expect(resolveEmailLocale('fr', 'en-US')).toBe('fr');
    expect(resolveEmailLocale(null, 'fr-FR')).toBe('fr');
  });
});

describe('password reset email template', () => {
  const prevPublicUrl = process.env.APP_PUBLIC_URL;

  beforeAll(() => {
    process.env.APP_PUBLIC_URL = 'https://uat.agathatrack.com';
  });

  afterAll(() => {
    if (prevPublicUrl === undefined) {
      delete process.env.APP_PUBLIC_URL;
    } else {
      process.env.APP_PUBLIC_URL = prevPublicUrl;
    }
  });

  it('builds English multipart content with branding and CTA', () => {
    const { subject, text, html } = buildPasswordResetEmail({ locale: 'en', code: '482915' });

    expect(subject).toBe('Your AgathaTrack password reset code');
    expect(text).toContain('482915');
    expect(text).toContain('https://uat.agathatrack.com/forgot-password');
    expect(text).toContain("If you didn't request this");

    expect(html).toContain('AgathaTrack');
    expect(html).toContain('#755B68');
    expect(html).toContain('cid:agatha-logo');
    expect(html).toContain('482915');
    expect(html).toContain('Open AgathaTrack');
    expect(html).toContain('https://uat.agathatrack.com/forgot-password');
    expect(html).toContain('uat.agathatrack.com');
  });

  it('builds French multipart content', () => {
    const { subject, text, html } = buildPasswordResetEmail({ locale: 'fr', code: '123456' });

    expect(subject).toBe('Votre code de réinitialisation AgathaTrack');
    expect(text).toContain('123456');
    expect(text).toContain('Il expire dans 15 minutes.');
    expect(text).toContain("Si vous n'avez pas demandé ceci");

    expect(html).toContain('Réinitialisez votre mot de passe');
    expect(html).toContain('Ouvrir AgathaTrack');
    expect(html).toContain('123456');
  });

  it('escapes HTML in user-controlled code values', () => {
    const { html } = buildPasswordResetEmail({ locale: 'en', code: '<script>' });
    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;');
  });
});

describe('email layout', () => {
  it('includes preheader and footer host from APP_PUBLIC_URL', () => {
    const prev = process.env.APP_PUBLIC_URL;
    process.env.APP_PUBLIC_URL = 'https://prod.agathatrack.com/';
    try {
      const html = renderEmailLayout({
        title: 'Test',
        preheader: 'Preview line',
        bodyHtml: '<p>Body</p>',
        ctaUrl: 'https://prod.agathatrack.com/forgot-password',
        ctaLabel: 'Go',
      });
      expect(html).toContain('Preview line');
      expect(html).toContain('prod.agathatrack.com');
    } finally {
      if (prev === undefined) delete process.env.APP_PUBLIC_URL;
      else process.env.APP_PUBLIC_URL = prev;
    }
  });
});

describe('email i18n helpers', () => {
  it('formats placeholders', () => {
    const strings = getEmailStrings('en', 'passwordReset');
    expect(formatEmailString(strings.textIntro, { code: '999999' })).toContain('999999');
  });

  it('reads public URL helpers', () => {
    const prev = process.env.APP_PUBLIC_URL;
    process.env.APP_PUBLIC_URL = 'https://example.com/app/';
    try {
      expect(getPublicUrl()).toBe('https://example.com/app');
      expect(getPublicHost()).toBe('example.com');
    } finally {
      if (prev === undefined) delete process.env.APP_PUBLIC_URL;
      else process.env.APP_PUBLIC_URL = prev;
    }
  });
});
