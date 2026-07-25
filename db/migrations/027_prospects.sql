-- J4 Phase 1: org-scoped lightweight prospect records (G0 §9, I6).

CREATE TABLE IF NOT EXISTS prospects (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL DEFAULT '',
  email VARCHAR(255),
  phone VARCHAR(50),
  notes TEXT DEFAULT '',
  lawful_basis_attested_at TIMESTAMPTZ,
  lawful_basis_attested_by UUID REFERENCES users(id) ON DELETE SET NULL,
  opt_out_at TIMESTAMPTZ,
  retention_category TEXT NOT NULL DEFAULT 'manual_contact',
  creation_source VARCHAR(32) NOT NULL DEFAULT 'manual_shelter_entry',
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT prospects_retention_category_check
    CHECK (retention_category IN ('manual_contact', 'declined_archived', 'prospect_relationship')),
  CONSTRAINT prospects_creation_source_check
    CHECK (creation_source IN ('manual_shelter_entry', 'registered_user'))
);

CREATE INDEX IF NOT EXISTS idx_prospects_org_id
  ON prospects(organization_id);

CREATE INDEX IF NOT EXISTS idx_prospects_email_lower
  ON prospects (LOWER(email))
  WHERE email IS NOT NULL;
