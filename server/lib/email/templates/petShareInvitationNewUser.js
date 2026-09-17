import { getPublicUrl } from '../branding.js';
import { normalizeLocale } from '../locale.js';
import { renderEmailLayout } from '../layout.js';

const STRINGS = {
  en: {
    subject: 'You have been invited to follow pets on AgathaTrack',
    title: 'Pet sharing invitation',
    preheader: 'Create your account to accept the invitation',
    intro: (inviterName, petNames) =>
      `${inviterName} invited you to follow ${petNames} on AgathaTrack.`,
    cta: 'Create your account',
    expiry: 'This invitation expires in 7 days.',
    security: 'If you were not expecting this email, you can ignore it.',
    textIntro: (inviterName, petNames) =>
      `${inviterName} invited you to follow ${petNames} on AgathaTrack.`,
    textCta: (url) => `Create your account to accept: ${url}`,
    textExpiry: 'This invitation expires in 7 days.',
    textSecurity: 'If you were not expecting this email, you can ignore it.',
  },
  fr: {
    subject: 'Vous avez été invité à suivre des animaux sur AgathaTrack',
    title: 'Invitation de partage',
    preheader: 'Créez votre compte pour accepter l’invitation',
    intro: (inviterName, petNames) =>
      `${inviterName} vous a invité à suivre ${petNames} sur AgathaTrack.`,
    cta: 'Créer un compte',
    expiry: 'Cette invitation expire dans 7 jours.',
    security: 'Si vous n’attendiez pas cet e-mail, vous pouvez l’ignorer.',
    textIntro: (inviterName, petNames) =>
      `${inviterName} vous a invité à suivre ${petNames} sur AgathaTrack.`,
    textCta: (url) => `Créez votre compte pour accepter : ${url}`,
    textExpiry: 'Cette invitation expire dans 7 jours.',
    textSecurity: 'Si vous n’attendiez pas cet e-mail, vous pouvez l’ignorer.',
  },
};

function formatPetNames(pets) {
  const names = (pets || []).map((p) => p.pet_name || 'a pet').filter(Boolean);
  if (names.length === 0) return 'pets';
  if (names.length === 1) return names[0];
  if (names.length === 2) return `${names[0]} and ${names[1]}`;
  return `${names.slice(0, -1).join(', ')}, and ${names[names.length - 1]}`;
}

/**
 * Build localized pet-share invitation email for new users.
 *
 * @param {{ locale?: string, inviterName: string, pets: Array<{ pet_name?: string }>, code: string }} options
 */
export function buildPetShareInvitationNewUserEmail({
  locale = 'en',
  inviterName,
  pets,
  code,
}) {
  const lang = normalizeLocale(locale);
  const strings = STRINGS[lang] || STRINGS.en;
  const petNames = formatPetNames(pets);
  const inviteUrl = `${getPublicUrl()}/invite/${code}`;

  const text = [
    strings.textIntro(inviterName, petNames),
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
<p style="margin:0 0 16px 0;">${strings.intro(inviterName, petNames)}</p>
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
