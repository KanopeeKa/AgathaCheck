-- J2 Phase 1: foster requests, targets, and responses (G0 §5.4, audit catalog).

CREATE TABLE IF NOT EXISTS foster_requests (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  message TEXT NOT NULL DEFAULT '',
  status VARCHAR(32) NOT NULL DEFAULT 'draft',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_requests_status_check
    CHECK (status IN ('draft', 'sent', 'cancelled'))
);

CREATE TABLE IF NOT EXISTS foster_request_pets (
  id UUID PRIMARY KEY,
  foster_request_id UUID NOT NULL REFERENCES foster_requests(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (foster_request_id, pet_id)
);

CREATE TABLE IF NOT EXISTS foster_request_targets (
  id UUID PRIMARY KEY,
  foster_request_id UUID NOT NULL REFERENCES foster_requests(id) ON DELETE CASCADE,
  org_foster_parent_id UUID NOT NULL REFERENCES org_foster_parents(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (foster_request_id, org_foster_parent_id)
);

CREATE TABLE IF NOT EXISTS foster_request_responses (
  id UUID PRIMARY KEY,
  foster_request_id UUID NOT NULL REFERENCES foster_requests(id) ON DELETE CASCADE,
  org_foster_parent_id UUID NOT NULL REFERENCES org_foster_parents(id) ON DELETE CASCADE,
  response VARCHAR(32) NOT NULL DEFAULT 'pending',
  message TEXT NOT NULL DEFAULT '',
  earliest_availability DATE,
  capacity_confirmed_at TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_request_responses_response_check
    CHECK (response IN ('can_help', 'cannot_help', 'pending')),
  UNIQUE (foster_request_id, org_foster_parent_id)
);

CREATE INDEX IF NOT EXISTS idx_foster_requests_org_id
  ON foster_requests(organization_id);

CREATE INDEX IF NOT EXISTS idx_foster_request_pets_request_id
  ON foster_request_pets(foster_request_id);

CREATE INDEX IF NOT EXISTS idx_foster_request_targets_request_id
  ON foster_request_targets(foster_request_id);

CREATE INDEX IF NOT EXISTS idx_foster_request_responses_request_id
  ON foster_request_responses(foster_request_id);
