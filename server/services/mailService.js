import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { mailFrom, mailTransporter } from '../config/mail.js';
import { LOGO_CID } from '../lib/email/branding.js';
import { buildPasswordResetEmail } from '../lib/email/templates/passwordReset.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const logoPath = path.join(__dirname, '../assets/logo.png');

function logoAttachment() {
  if (!fs.existsSync(logoPath)) return [];
  return [
    {
      filename: 'logo.png',
      path: logoPath,
      cid: LOGO_CID,
    },
  ];
}

/**
 * Send a transactional email with optional branded HTML and inline logo.
 */
export async function sendTransactionalEmail({ to, subject, text, html }) {
  const message = {
    from: mailFrom,
    to,
    subject,
    text,
  };

  if (html) {
    message.html = html;
    message.attachments = logoAttachment();
  }

  await mailTransporter.sendMail(message);
}

export async function sendPasswordResetEmail(to, code, locale = 'en') {
  const { subject, text, html } = buildPasswordResetEmail({ locale, code });
  await sendTransactionalEmail({ to, subject, text, html });
}
