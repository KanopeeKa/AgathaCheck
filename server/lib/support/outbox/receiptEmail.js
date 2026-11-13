import { getPublicUrl } from '../../email/branding.js';
import { formatEmailString, getEmailStrings } from '../../email/i18n.js';
import { normalizeLocale } from '../../email/locale.js';
import { renderEmailLayout } from '../../email/layout.js';

/**
 * @param {{ locale?: string, reference: string }} options
 */
export function buildSupportReceiptEmail({ locale = 'en', reference }) {
  const lang = normalizeLocale(locale);
  const strings = getEmailStrings(lang, 'supportReceipt');
  const contactUrl = `${getPublicUrl()}/contact`;

  const text = [
    formatEmailString(strings.textIntro, { reference }),
    strings.textBody,
    '',
    formatEmailString(strings.textContact, { url: contactUrl }),
    '',
    `— AgathaTrack`,
    getPublicUrl().replace(/^https?:\/\//, ''),
  ].join('\n');

  const bodyHtml = `
<p style="margin:0 0 16px 0;">${formatEmailString(strings.intro, { reference })}</p>
<p style="margin:0 0 16px 0;font-size:14px;color:#555555;">${strings.bodyDetail}</p>
<p style="margin:0;font-size:14px;color:#777777;">${strings.footer}</p>`;

  const html = renderEmailLayout({
    title: strings.title,
    preheader: strings.preheader,
    bodyHtml,
    ctaUrl: contactUrl,
    ctaLabel: strings.cta,
  });

  return {
    subject: formatEmailString(strings.subject, { reference }),
    text,
    html,
  };
}
