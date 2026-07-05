-- Org-scoped foster contact details for registered members and external fosters.

ALTER TABLE organization_users
  ADD COLUMN IF NOT EXISTS foster_phone VARCHAR(50) DEFAULT '',
  ADD COLUMN IF NOT EXISTS foster_address TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS admin_notes TEXT DEFAULT '';

ALTER TABLE org_foster_parents
  ADD COLUMN IF NOT EXISTS foster_address TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS lawful_basis_attested_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS lawful_basis_attested_by UUID REFERENCES users(id) ON DELETE SET NULL;
