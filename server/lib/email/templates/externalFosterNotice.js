import { getPublicUrl } from '../branding.js';
import { formatEmailString, getEmailStrings } from '../i18n.js';
import { normalizeLocale } from '../locale.js';
import { renderEmailLayout } from '../layout.js';

/**
 * Art. 14 informational email when an organisation adds an external foster contact.
 */
export function buildExternalFosterNoticeEmail({
  locale = 'en',
  orgName,
  privacyUrl,
}) {
  const lang = normalizeLocale(locale);
  const strings = getEmailStrings(lang, 'externalFosterNotice');
  const rightsUrl = privacyUrl || `${getPublicUrl()}/legal/privacy-notice`;

  const text = [
    formatEmailString(strings.textIntro, { orgName }),
    strings.textWhy,
    '',
    formatEmailString(strings.textRights, { url: rightsUrl }),
    '',
    strings.textContact,
    '',
    '— AgathaTrack',
  ].join('\n');

  const bodyHtml = `
<p style="margin:0 0 16px 0;">${formatEmailString(strings.intro, { orgName })}</p>
<p style="margin:0 0 16px 0;">${strings.why}</p>
<p style="margin:0 0 16px 0;">${formatEmailString(strings.rights, { url: rightsUrl })}</p>
<p style="margin:0;font-size:14px;color:#777777;">${strings.contact}</p>`;

  const html = renderEmailLayout({
    title: strings.title,
    preheader: strings.preheader,
    bodyHtml,
    ctaUrl: rightsUrl,
    ctaLabel: strings.cta,
  });

  return {
    subject: formatEmailString(strings.subject, { orgName }),
    text,
    html,
  };
}
