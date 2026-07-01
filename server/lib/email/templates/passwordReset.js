import { getPublicUrl } from '../branding.js';
import { formatEmailString, getEmailStrings } from '../i18n.js';
import { normalizeLocale } from '../locale.js';
import { renderCodeBlock, renderEmailLayout } from '../layout.js';

/**
 * Build localized password-reset email content (subject, plain text, HTML).
 *
 * @param {{ locale?: string, code: string }} options
 */
export function buildPasswordResetEmail({ locale = 'en', code }) {
  const lang = normalizeLocale(locale);
  const strings = getEmailStrings(lang, 'passwordReset');
  const forgotPasswordUrl = `${getPublicUrl()}/forgot-password`;

  const text = [
    formatEmailString(strings.textIntro, { code }),
    strings.textExpiry,
    '',
    formatEmailString(strings.textCta, { url: forgotPasswordUrl }),
    '',
    strings.textSecurity,
    '',
    `— Agatha Track`,
    getPublicUrl().replace(/^https?:\/\//, ''),
  ].join('\n');

  const bodyHtml = `
<p style="margin:0 0 16px 0;">${strings.intro}</p>
<p style="margin:0 0 8px 0;font-size:14px;font-weight:bold;color:#555555;">${strings.codeLabel}</p>
${renderCodeBlock(code)}
<p style="margin:0 0 16px 0;font-size:14px;color:#555555;">${strings.expiry}</p>
<p style="margin:0;font-size:14px;color:#777777;">${strings.security}</p>`;

  const html = renderEmailLayout({
    title: strings.title,
    preheader: strings.preheader,
    bodyHtml,
    ctaUrl: forgotPasswordUrl,
    ctaLabel: strings.cta,
  });

  return {
    subject: strings.subject,
    text,
    html,
  };
}
