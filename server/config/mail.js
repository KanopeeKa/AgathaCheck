import nodemailer from 'nodemailer';

/**
 * Password-reset email (SMTP) env vars for UAT/cPanel:
 * UAT_SMTP_HOST, UAT_SMTP_PORT, UAT_SMTP_SECURE, UAT_MAIL_FROM,
 * and credentials as UAT_MAIL_USER / UAT_MAIL_PASS (legacy aliases
 * UAT_mail_user / UAT_mail_pass are still accepted).
 */
function env(...keys) {
  for (const key of keys) {
    const value = process.env[key];
    if (value !== undefined && value !== '') return value;
  }
  return undefined;
}

export function isSmtpConfigured() {
  return Boolean(env('UAT_SMTP_HOST'));
}

function buildSmtpOptions() {
  const port = Number(env('UAT_SMTP_PORT') || 465);
  const secureRaw = env('UAT_SMTP_SECURE');
  const secure =
    secureRaw !== undefined
      ? String(secureRaw).toLowerCase() === 'true'
      : port === 465;

  return {
    host: env('UAT_SMTP_HOST'),
    port,
    secure,
    auth: {
      user: env('UAT_MAIL_USER', 'UAT_mail_user'),
      pass: env('UAT_MAIL_PASS', 'UAT_mail_pass'),
    },
  };
}

function shouldUseJsonTransport() {
  if (process.env.NODE_ENV === 'test') return true;
  // Local dev without SMTP: skip real delivery so forgot-password can expose the code.
  if (process.env.NODE_ENV !== 'production' && !isSmtpConfigured()) return true;
  return false;
}

let mailFromValue;
export function getMailFrom() {
  if (mailFromValue === undefined) {
    mailFromValue = env('UAT_MAIL_FROM');
  }
  return mailFromValue;
}

let transporter;
export function getMailTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport(
      shouldUseJsonTransport() ? { jsonTransport: true } : buildSmtpOptions()
    );
  }
  return transporter;
}
