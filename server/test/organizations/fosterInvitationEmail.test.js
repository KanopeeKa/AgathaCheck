import {
  EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER,
  listEmailTemplatesForOrg,
  renderEmailTemplateFields,
  resolveEmailTemplate,
} from '../../lib/emailTemplates.js';

describe('emailTemplates', () => {
  it('lists default EN/FR templates for foster invitation', async () => {
    const pool = { query: async () => ({ rows: [] }) };
    const templates = await listEmailTemplatesForOrg(pool, 'org-1');
    const keys = templates.map((t) => `${t.template_key}:${t.locale}`);
    expect(keys).toContain(`${EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER}:en`);
    expect(keys).toContain(`${EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER}:fr`);
  });

  it('renders placeholder variables', () => {
    const rendered = renderEmailTemplateFields({
      subject: 'Hello {{org.name}}',
      body_html: '<p>{{inviter.name}}</p>',
      body_text: '{{signup_url}}',
    }, {
      orgName: 'Rescue Hearts',
      inviterName: 'Alice',
      signupUrl: 'https://example.com/signup',
    });
    expect(rendered.subject).toBe('Hello Rescue Hearts');
    expect(rendered.body_html).toContain('Alice');
    expect(rendered.body_text).toBe('https://example.com/signup');
  });

  it('uses DB override when present', async () => {
    const pool = {
      query: async (sql) => {
        if (sql.includes('FROM email_templates')) {
          return {
            rows: [{
              subject: 'Custom {{org.name}}',
              body_html: '<p>Custom</p>',
              body_text: 'Custom text',
            }],
          };
        }
        return { rows: [] };
      },
    };
    const rendered = await resolveEmailTemplate(pool, {
      orgId: 'org-1',
      templateKey: EMAIL_TEMPLATE_FOSTER_INVITATION_NEW_USER,
      locale: 'en',
      vars: { orgName: 'Shelter' },
    });
    expect(rendered.subject).toBe('Custom Shelter');
  });
});
