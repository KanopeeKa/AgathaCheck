-- Org custody: care holders, org connections, custody transfers, shadows, home-hide prefs.

BEGIN;

ALTER TABLE pets ADD COLUMN IF NOT EXISTS care_holder_kind VARCHAR(10);
ALTER TABLE pets ADD COLUMN IF NOT EXISTS care_holder_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE pets ADD COLUMN IF NOT EXISTS care_holder_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL;

UPDATE pets
SET care_holder_kind = 'org',
    care_holder_org_id = organization_id
WHERE organization_id IS NOT NULL
  AND care_holder_kind IS NULL;

UPDATE pets
SET care_holder_kind = 'user',
    care_holder_user_id = user_id
WHERE organization_id IS NULL
  AND care_holder_kind IS NULL;

ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS shadow_snapshot JSONB NOT NULL DEFAULT '{}';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS frozen_at TIMESTAMPTZ;

UPDATE archived_pets SET frozen_at = archived_at WHERE frozen_at IS NULL AND archived_at IS NOT NULL;
UPDATE archived_pets SET frozen_at = created_at WHERE frozen_at IS NULL;

CREATE TABLE IF NOT EXISTS org_connections (
  id UUID PRIMARY KEY,
  org_low_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_high_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  revoked_by_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  CONSTRAINT org_connections_distinct CHECK (org_low_id <> org_high_id),
  UNIQUE (org_low_id, org_high_id)
);

CREATE INDEX IF NOT EXISTS idx_org_connections_low ON org_connections(org_low_id);
CREATE INDEX IF NOT EXISTS idx_org_connections_high ON org_connections(org_high_id);

CREATE TABLE IF NOT EXISTS org_connection_requests (
  id UUID PRIMARY KEY,
  requesting_org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  target_org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  token VARCHAR(64) NOT NULL UNIQUE,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  expires_at TIMESTAMPTZ NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  CONSTRAINT org_connection_requests_distinct CHECK (requesting_org_id <> target_org_id)
);

CREATE INDEX IF NOT EXISTS idx_org_connection_requests_target
  ON org_connection_requests(target_org_id, status);

CREATE TABLE IF NOT EXISTS custody_transfers (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  transfer_kind VARCHAR(32) NOT NULL,
  from_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  from_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  to_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  requested_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  requesting_org_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  cancel_reason TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at TIMESTAMPTZ,
  responded_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_custody_transfers_pet_status
  ON custody_transfers(pet_id, status);

CREATE INDEX IF NOT EXISTS idx_custody_transfers_to_org
  ON custody_transfers(to_org_id, status);

CREATE TABLE IF NOT EXISTS org_pet_home_hidden (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, pet_id)
);

CREATE INDEX IF NOT EXISTS idx_org_pet_home_hidden_org
  ON org_pet_home_hidden(organization_id, pet_id);

COMMIT;
