import { getPublicUrl } from '../branding.js';
import { resolveEmailLocale } from '../locale.js';
import { renderEmailLayout } from '../layout.js';
import {
  EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER,
  resolveEmailTemplate,
} from '../../emailTemplates.js';

export async function buildFosterInvitationNewUserEmail(pool, {
  orgId,
  locale,
  orgName,
  orgDescription = '',
  orgContactEmail = '',
  orgLogoUrl = '',
  inviterName,
  inviterRole,
  signupUrl,
}) {
  const resolvedLocale = resolveEmailLocale(locale);
  const signup = signupUrl || `${getPublicUrl()}/signup`;
  const rendered = await resolveEmailTemplate(pool, {
    orgId,
    templateKey: EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER,
    locale: resolvedLocale,
    vars: {
      orgName,
      orgDescription,
      orgContactEmail,
      orgLogoUrl,
      inviterName,
      inviterRole,
      signupUrl: signup,
    },
  });
  if (!rendered) {
    throw new Error('Foster invitation email template not found');
  }

  const html = renderEmailLayout({
    title: orgName,
    preheader: rendered.subject,
    bodyHtml: rendered.body_html,
    ctaUrl: signup,
    ctaLabel: resolvedLocale === 'fr' ? 'Créer un compte' : 'Create your account',
  });

  return {
    subject: rendered.subject,
    text: rendered.body_text,
    html,
  };
}
