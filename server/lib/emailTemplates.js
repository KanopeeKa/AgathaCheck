/**
 * Org email template defaults and DB overrides (v4 Phase G).
 */
import { v4 as uuidv4 } from 'uuid';

export const EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER = 'foster_invitation_new_user';
export const EMAIL_TEMPLATE_FOSTER_INVITATION_EXISTING_USER = 'foster_invitation_existing_user';

const SUPPORTED_LOCALES = new Set(['en', 'fr']);

const DEFAULT_TEMPLATES = {
  [EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER]: {
    en: {
      subject: 'Invitation to foster via {{org.name}} on Agatha Track',
      body_html:
        '<p>{{org.name}} invited you to begin fostering through Agatha Track.</p>'
        + '<p>{{org.description}}</p>'
        + '<p>Contact: {{org.contact_email}}</p>'
        + '<p>Invited by {{inviter.name}} ({{inviter.role}}).</p>'
        + '<p><a href="{{signup_url}}">Create your account</a></p>',
      body_text:
        '{{org.name}} invited you to foster via Agatha Track.\n'
        + '{{org.description}}\nContact: {{org.contact_email}}\n'
        + 'Invited by {{inviter.name}} ({{inviter.role}}).\n'
        + 'Sign up: {{signup_url}}',
    },
    fr: {
      subject: 'Invitation à accueillir via {{org.name}} sur Agatha Track',
      body_html:
        '<p>{{org.name}} vous invite à accueillir des animaux via Agatha Track.</p>'
        + '<p>{{org.description}}</p>'
        + '<p>Contact : {{org.contact_email}}</p>'
        + '<p>Invitation envoyée par {{inviter.name}} ({{inviter.role}}).</p>'
        + '<p><a href="{{signup_url}}">Créer votre compte</a></p>',
      body_text:
        '{{org.name}} vous invite à accueillir via Agatha Track.\n'
        + '{{org.description}}\nContact : {{org.contact_email}}\n'
        + 'Invitation de {{inviter.name}} ({{inviter.role}}).\n'
        + 'Créer un compte : {{signup_url}}',
    },
  },
  [EMAIL_TEMPLATE_FOSTER_INVITATION_EXISTING_USER]: {
    en: {
      subject: 'Foster for {{org.name}}',
      body_html:
        '<p>{{org.name}} invited you to begin fostering on Agatha Track.</p>'
        + '<p>Sign in to review the invitation in your notifications.</p>',
      body_text:
        '{{org.name}} invited you to begin fostering on Agatha Track.\n'
        + 'Sign in to review the invitation in your notifications.',
    },
    fr: {
      subject: 'Accueil pour {{org.name}}',
      body_html:
        '<p>{{org.name}} vous invite à accueillir sur Agatha Track.</p>'
        + '<p>Connectez-vous pour voir l\'invitation dans vos notifications.</p>',
      body_text:
        '{{org.name}} vous invite à accueillir sur Agatha Track.\n'
        + 'Connectez-vous pour voir l\'invitation dans vos notifications.',
    },
  },
};

function normaliseLocale(locale) {
  const base = String(locale || 'en').toLowerCase().split('-')[0];
  return SUPPORTED_LOCALES.has(base) ? base : 'en';
}

function defaultFor(templateKey, locale) {
  const lang = normaliseLocale(locale);
  const template = DEFAULT_TEMPLATES[templateKey];
  if (!template) return null;
  return template[lang] || template.en;
}

function replacePlaceholders(text, vars) {
  let out = String(text || '');
  for (const [key, value] of Object.entries(vars)) {
    const safe = value == null ? '' : String(value);
    out = out.split(`{{${key}}}`).join(safe);
  }
  return out;
}

export function renderEmailTemplateFields(template, vars) {
  const flatVars = {
    'org.name': vars.orgName ?? '',
    'org.description': vars.orgDescription ?? '',
    'org.contact_email': vars.orgContactEmail ?? '',
    'org.logo_url': vars.orgLogoUrl ?? '',
    'inviter.name': vars.inviterName ?? '',
    'inviter.role': vars.inviterRole ?? '',
    signup_url: vars.signupUrl ?? '',
  };
  return {
    subject: replacePlaceholders(template.subject, flatVars),
    body_html: replacePlaceholders(template.body_html, flatVars),
    body_text: replacePlaceholders(template.body_text, flatVars),
  };
}

export async function listEmailTemplatesForOrg(pool, orgId) {
  const result = await pool.query(
    `SELECT template_key, locale, subject, body_html, body_text, updated_at
     FROM email_templates
     WHERE organization_id = $1
     ORDER BY template_key, locale`,
    [orgId],
  );
  const overrides = new Map();
  for (const row of result.rows) {
    overrides.set(`${row.template_key}:${row.locale}`, row);
  }

  const templates = [];
  for (const templateKey of Object.keys(DEFAULT_TEMPLATES)) {
    for (const locale of SUPPORTED_LOCALES) {
      const override = overrides.get(`${templateKey}:${locale}`);
      const defaults = defaultFor(templateKey, locale);
      templates.push({
        template_key: templateKey,
        locale,
        label: templateKey.replace(/_/g, ' '),
        subject: override?.subject ?? defaults.subject,
        body_html: override?.body_html ?? defaults.body_html,
        body_text: override?.body_text ?? defaults.body_text,
        is_customised: Boolean(override),
        updated_at: override?.updated_at ?? null,
      });
    }
  }
  return templates;
}

export async function upsertEmailTemplate(pool, {
  orgId, templateKey, locale, subject, bodyHtml, bodyText,
}) {
  const lang = normaliseLocale(locale);
  if (!DEFAULT_TEMPLATES[templateKey]) {
    return { error: 'Unknown email template', status: 404 };
  }
  const result = await pool.query(
    `INSERT INTO email_templates (
       id, organization_id, template_key, locale, subject, body_html, body_text, updated_at
     ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
     ON CONFLICT (organization_id, template_key, locale)
     DO UPDATE SET
       subject = EXCLUDED.subject,
       body_html = EXCLUDED.body_html,
       body_text = EXCLUDED.body_text,
       updated_at = NOW()
     RETURNING template_key, locale, subject, body_html, body_text, updated_at`,
    [uuidv4(), orgId, templateKey, lang, subject, bodyHtml, bodyText],
  );
  return { row: result.rows[0] };
}

export async function resolveEmailTemplate(pool, {
  orgId, templateKey, locale, vars = {},
}) {
  const lang = normaliseLocale(locale);
  const override = await pool.query(
    `SELECT subject, body_html, body_text
     FROM email_templates
     WHERE organization_id = $1 AND template_key = $2 AND locale = $3`,
    [orgId, templateKey, lang],
  );
  const base = override.rows[0] || defaultFor(templateKey, lang);
  if (!base) return null;
  return renderEmailTemplateFields(base, vars);
}
