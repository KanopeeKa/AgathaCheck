import { buildExternalFosterNoticeEmail } from '../lib/email/templates/externalFosterNotice.js';

describe('external foster notice email template', () => {
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

  it('builds English multipart content with org name and privacy link', () => {
    const { subject, text, html } = buildExternalFosterNoticeEmail({
      locale: 'en',
      orgName: 'Happy Paws Shelter',
    });

    expect(subject).toContain('Happy Paws Shelter');
    expect(text).toContain('Happy Paws Shelter');
    expect(text).toContain('https://uat.agathatrack.com/legal/privacy-notice');
    expect(text).toContain('AgathaTrack');

    expect(html).toContain('Happy Paws Shelter');
    expect(html).toContain('https://uat.agathatrack.com/legal/privacy-notice');
  });

  it('uses a custom privacy URL when provided', () => {
    const { text, html } = buildExternalFosterNoticeEmail({
      locale: 'en',
      orgName: 'Shelter',
      privacyUrl: 'https://example.com/privacy',
    });

    expect(text).toContain('https://example.com/privacy');
    expect(html).toContain('https://example.com/privacy');
  });

  it('builds French multipart content', () => {
    const { subject, text, html } = buildExternalFosterNoticeEmail({
      locale: 'fr',
      orgName: 'Refuge du Bonheur',
    });

    expect(subject).toContain('Refuge du Bonheur');
    expect(text).toContain('Refuge du Bonheur');
    expect(html).toContain('Refuge du Bonheur');
  });
});
