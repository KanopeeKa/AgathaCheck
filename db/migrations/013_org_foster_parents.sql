-- External foster parents (no app account). Member foster parents come from
-- organization_users with role admin/foster/super_admin (see foster-parents API).

CREATE TABLE IF NOT EXISTS org_foster_parents (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL DEFAULT '',
  email VARCHAR(255),
  phone VARCHAR(50),
  notes TEXT DEFAULT '',
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_org_foster_parents_org_id
  ON org_foster_parents(organization_id);
