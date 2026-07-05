function restoreEnv(key, prev) {
  if (prev === undefined) {
    delete process.env[key];
  } else {
    process.env[key] = prev;
  }
}

describe('mail config', () => {
  const envKeys = [
    'NODE_ENV',
    'UAT_SMTP_HOST',
    'UAT_SMTP_PORT',
    'UAT_SMTP_SECURE',
    'UAT_MAIL_FROM',
    'UAT_MAIL_USER',
    'UAT_MAIL_PASS',
  ];

  const saved = {};

  beforeEach(() => {
    jest.resetModules();
    for (const key of envKeys) {
      saved[key] = process.env[key];
    }
  });

  afterEach(() => {
    for (const key of envKeys) {
      restoreEnv(key, saved[key]);
    }
  });

  it('defaults secure to true when port is 465 and UAT_SMTP_SECURE is unset', async () => {
    delete process.env.UAT_SMTP_SECURE;
    process.env.UAT_SMTP_HOST = 'smtp.example.com';
    process.env.UAT_SMTP_PORT = '465';
    process.env.NODE_ENV = 'production';

    const { getMailTransporter } = await import('../config/mail.js');
    const transporter = getMailTransporter();

    expect(transporter.options.secure).toBe(true);
    expect(transporter.options.port).toBe(465);
  });

  it('uses jsonTransport in test mode', async () => {
    process.env.NODE_ENV = 'test';
    process.env.UAT_SMTP_HOST = 'smtp.example.com';

    const { getMailTransporter } = await import('../config/mail.js');
    const transporter = getMailTransporter();

    expect(transporter.transporter.name).toBe('JSONTransport');
  });

  it('uses jsonTransport outside production when SMTP is not configured', async () => {
    delete process.env.UAT_SMTP_HOST;
    process.env.NODE_ENV = 'development';

    const { getMailTransporter, isSmtpConfigured } = await import('../config/mail.js');

    expect(isSmtpConfigured()).toBe(false);
    const transporter = getMailTransporter();
    expect(transporter.transporter.name).toBe('JSONTransport');
  });

  it('reads SMTP settings lazily after env is available', async () => {
    process.env.NODE_ENV = 'production';
    delete process.env.UAT_SMTP_HOST;

    const { isSmtpConfigured, getMailFrom } = await import('../config/mail.js');
    expect(isSmtpConfigured()).toBe(false);
    expect(getMailFrom()).toBeUndefined();

    process.env.UAT_SMTP_HOST = 'smtp.example.com';
    process.env.UAT_MAIL_FROM = 'noreply@example.com';

    expect(isSmtpConfigured()).toBe(true);
    expect(getMailFrom()).toBe('noreply@example.com');
  });
});
