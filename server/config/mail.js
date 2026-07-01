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

const port = Number(env('UAT_SMTP_PORT') || 465);
const secureRaw = env('UAT_SMTP_SECURE');
const secure =
  secureRaw !== undefined
    ? String(secureRaw).toLowerCase() === 'true'
    : port === 465;

export const mailFrom = env('UAT_MAIL_FROM');

const smtpOptions = {
  host: env('UAT_SMTP_HOST'),
  port,
  secure,
  auth: {
    user: env('UAT_MAIL_USER', 'UAT_mail_user'),
    pass: env('UAT_MAIL_PASS', 'UAT_mail_pass'),
  },
};

export const mailTransporter = nodemailer.createTransport(
  process.env.NODE_ENV === 'test' ? { jsonTransport: true } : smtpOptions
);
