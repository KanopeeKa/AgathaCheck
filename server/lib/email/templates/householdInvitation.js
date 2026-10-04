import { getPublicUrl } from '../branding.js';
import { normalizeLocale } from '../locale.js';
import { renderEmailLayout } from '../layout.js';

const STRINGS = {
  en: {
    subject: 'You have been invited to a household on AgathaTrack',
    title: 'Household invitation',
    preheader: 'Create your account to join the household',
    intro: (inviterName, householdName) =>
      `${inviterName} invited you to join ${householdName} on AgathaTrack.`,
    cta: 'Create your account',
    expiry: 'This invitation expires in 14 days.',
    security: 'If you were not expecting this email, you can ignore it.',
    textIntro: (inviterName, householdName) =>
      `${inviterName} invited you to join ${householdName} on AgathaTrack.`,
    textCta: (url) => `Create your account to accept: ${url}`,
    textExpiry: 'This invitation expires in 14 days.',
    textSecurity: 'If you were not expecting this email, you can ignore it.',
  },
  fr: {
    subject: 'Vous avez été invité à rejoindre un foyer sur AgathaTrack',
    title: 'Invitation au foyer',
    preheader: 'Créez votre compte pour rejoindre le foyer',
    intro: (inviterName, householdName) =>
      `${inviterName} vous a invité à rejoindre ${householdName} sur AgathaTrack.`,
    cta: 'Créer un compte',
    expiry: 'Cette invitation expire dans 14 jours.',
    security: 'Si vous n’attendiez pas cet e-mail, vous pouvez l’ignorer.',
    textIntro: (inviterName, householdName) =>
      `${inviterName} vous a invité à rejoindre ${householdName} sur AgathaTrack.`,
    textCta: (url) => `Créez votre compte pour accepter : ${url}`,
    textExpiry: 'Cette invitation expire dans 14 jours.',
    textSecurity: 'Si vous n’attendiez pas cet e-mail, vous pouvez l’ignorer.',
  },
};

/**
 * @param {{ locale?: string, inviterName: string, householdName: string, code: string }} options
 */
export function buildHouseholdInvitationEmail({
  locale = 'en',
  inviterName,
  householdName,
  code,
}) {
  const lang = normalizeLocale(locale);
  const strings = STRINGS[lang] || STRINGS.en;
  const inviteUrl = `${getPublicUrl()}/household-invite/${code}`;
  const safeHousehold = householdName || 'a household';

  const text = [
    strings.textIntro(inviterName, safeHousehold),
    strings.textExpiry,
    '',
    strings.textCta(inviteUrl),
    '',
    strings.textSecurity,
    '',
    '— AgathaTrack',
    getPublicUrl().replace(/^https?:\/\//, ''),
  ].join('\n');

  const bodyHtml = `
<p style="margin:0 0 16px 0;">${strings.intro(inviterName, safeHousehold)}</p>
<p style="margin:0 0 16px 0;font-size:14px;color:#555555;">${strings.expiry}</p>
<p style="margin:0;font-size:14px;color:#777777;">${strings.security}</p>`;

  const html = renderEmailLayout({
    title: strings.title,
    preheader: strings.preheader,
    bodyHtml,
    ctaUrl: inviteUrl,
    ctaLabel: strings.cta,
  });

  return {
    subject: strings.subject,
    text,
    html,
  };
}
