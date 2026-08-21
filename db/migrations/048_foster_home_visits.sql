-- J1 Phase 5: foster home visit lifecycle (schedule, validate, checklist, photos).

CREATE TABLE IF NOT EXISTS foster_home_visits (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_foster_parent_id UUID NOT NULL REFERENCES org_foster_parents(id) ON DELETE CASCADE,
  status VARCHAR(16) NOT NULL DEFAULT 'scheduled',
  visit_date DATE NOT NULL,
  visit_time VARCHAR(5) NOT NULL DEFAULT '09:00',
  address TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  checklist_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  outcome VARCHAR(8),
  outcome_reason TEXT NOT NULL DEFAULT '',
  scheduled_by UUID REFERENCES users(id) ON DELETE SET NULL,
  validated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  validated_at TIMESTAMPTZ,
  cancelled_by UUID REFERENCES users(id) ON DELETE SET NULL,
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_home_visits_status_check
    CHECK (status IN ('scheduled', 'cancelled', 'validated')),
  CONSTRAINT foster_home_visits_outcome_check
    CHECK (outcome IS NULL OR outcome IN ('yes', 'no')),
  CONSTRAINT foster_home_visits_visit_time_check
    CHECK (visit_time ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
);

CREATE INDEX IF NOT EXISTS idx_foster_home_visits_org
  ON foster_home_visits(organization_id);

CREATE INDEX IF NOT EXISTS idx_foster_home_visits_parent
  ON foster_home_visits(organization_id, org_foster_parent_id, status);

CREATE TABLE IF NOT EXISTS foster_home_visit_attendees (
  id UUID PRIMARY KEY,
  home_visit_id UUID NOT NULL REFERENCES foster_home_visits(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  display_name TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_foster_home_visit_attendees_visit
  ON foster_home_visit_attendees(home_visit_id);

CREATE TABLE IF NOT EXISTS foster_home_visit_photos (
  id UUID PRIMARY KEY,
  home_visit_id UUID NOT NULL REFERENCES foster_home_visits(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  caption TEXT NOT NULL DEFAULT '',
  uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_foster_home_visit_photos_visit
  ON foster_home_visit_photos(home_visit_id);
