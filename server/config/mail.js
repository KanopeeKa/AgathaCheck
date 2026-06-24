import nodemailer from 'nodemailer';

/**
 * Required UAT email env vars:
 * UAT_SMTP_HOST, UAT_SMTP_PORT, UAT_SMTP_SECURE, UAT_mail_user,
 * UAT_mail_pass, UAT_MAIL_FROM
 */
export const mailFrom = process.env.UAT_MAIL_FROM;

const smtpOptions = {
  host: process.env.UAT_SMTP_HOST,
  port: Number(process.env.UAT_SMTP_PORT || 465),
  secure: String(process.env.UAT_SMTP_SECURE).toLowerCase() === 'true',
  auth: {
    user: process.env.UAT_mail_user,
    pass: process.env.UAT_mail_pass,
  },
};

export const mailTransporter = nodemailer.createTransport(
  process.env.NODE_ENV === 'test' ? { jsonTransport: true } : smtpOptions
);
