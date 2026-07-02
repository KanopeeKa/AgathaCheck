-- Foster placement lifecycle (Inc 4): pending → in_progress → not_in_foster.

CREATE TABLE IF NOT EXISTS foster_placements (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  foster_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  org_foster_parent_id UUID REFERENCES org_foster_parents(id) ON DELETE SET NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending',
  start_date DATE,
  end_date DATE,
  notes TEXT DEFAULT '',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  responded_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_foster_placements_one_active_pet
  ON foster_placements(pet_id)
  WHERE status IN ('pending', 'in_progress');

CREATE INDEX IF NOT EXISTS idx_foster_placements_foster_user_status
  ON foster_placements(foster_user_id, status);

CREATE INDEX IF NOT EXISTS idx_foster_placements_org_id
  ON foster_placements(organization_id);
