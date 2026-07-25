-- J4 Phase 2: adoption visit scheduling (G0 §5.5, §8).

CREATE TABLE IF NOT EXISTS adoption_visits (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  prospect_id UUID REFERENCES prospects(id) ON DELETE SET NULL,
  fostering_session_id UUID REFERENCES foster_placements(id) ON DELETE SET NULL,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(32) NOT NULL DEFAULT 'scheduled',
  outcome VARCHAR(32),
  outcome_notes TEXT NOT NULL DEFAULT '',
  assigned_foster_parent_id UUID REFERENCES org_foster_parents(id) ON DELETE SET NULL,
  validation_status VARCHAR(32) NOT NULL DEFAULT 'pending',
  validated_at TIMESTAMPTZ,
  validated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT adoption_visits_status_check
    CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  CONSTRAINT adoption_visits_outcome_check
    CHECK (outcome IS NULL OR outcome IN ('positive', 'negative', 'no_show')),
  CONSTRAINT adoption_visits_validation_status_check
    CHECK (validation_status IN ('pending', 'validated', 'rejected'))
);

CREATE INDEX IF NOT EXISTS idx_adoption_visits_org_id
  ON adoption_visits(organization_id);

CREATE INDEX IF NOT EXISTS idx_adoption_visits_session_id
  ON adoption_visits(fostering_session_id)
  WHERE fostering_session_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_adoption_visits_prospect_id
  ON adoption_visits(prospect_id)
  WHERE prospect_id IS NOT NULL;
