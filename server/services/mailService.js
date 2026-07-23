import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

import { getMailFrom, getMailTransporter } from '../config/mail.js';
import { LOGO_CID, ORGANIZATION_LOGO_CID } from '../lib/email/branding.js';
import { buildPasswordResetEmail } from '../lib/email/templates/passwordReset.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const assetsDir = path.join(__dirname, '../assets');

function logoAttachment({ organization = false } = {}) {
  const filename = organization ? 'logo-teal.png' : 'logo-plum.png';
  const logoPath = path.join(assetsDir, filename);
  if (!fs.existsSync(logoPath)) return [];
  return [
    {
      filename,
      path: logoPath,
      cid: organization ? ORGANIZATION_LOGO_CID : LOGO_CID,
    },
  ];
}

/**
 * Send a transactional email with optional branded HTML and inline logo.
 */
export async function sendTransactionalEmail({ to, subject, text, html, organization = false }) {
  const message = {
    from: getMailFrom(),
    to,
    subject,
    text,
  };

  if (html) {
    message.html = html;
    message.attachments = logoAttachment({ organization });
  }

  await getMailTransporter().sendMail(message);
}

export async function sendPasswordResetEmail(to, code, locale = 'en') {
  const { subject, text, html } = buildPasswordResetEmail({ locale, code });
  await sendTransactionalEmail({ to, subject, text, html });
}
