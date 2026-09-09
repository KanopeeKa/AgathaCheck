-- Phase E: guardian-facing care safeguards (weight-only V1).

CREATE TABLE IF NOT EXISTS care_safeguards (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  safeguard_type VARCHAR(50) NOT NULL,
  safeguard_key VARCHAR(100) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  policy_version VARCHAR(20) NOT NULL,
  copy_key VARCHAR(100) NOT NULL,
  evidence_json JSONB NOT NULL DEFAULT '{}',
  dismissed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS care_safeguards_pet_key_idx
  ON care_safeguards (pet_id, safeguard_key);

CREATE INDEX IF NOT EXISTS care_safeguards_pet_status_idx
  ON care_safeguards (pet_id, status);
