-- Org-customisable transactional email templates (v4 Phase G).
CREATE TABLE IF NOT EXISTS email_templates (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  template_key VARCHAR(100) NOT NULL,
  locale VARCHAR(10) NOT NULL DEFAULT 'en',
  subject TEXT NOT NULL,
  body_html TEXT NOT NULL,
  body_text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, template_key, locale)
);

CREATE INDEX IF NOT EXISTS idx_email_templates_org_key
  ON email_templates (organization_id, template_key);
