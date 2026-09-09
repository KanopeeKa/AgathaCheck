-- CP-3: historical care establishment transitions (weight monitoring V1)

CREATE TABLE IF NOT EXISTS care_establishments (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  care_family VARCHAR(50) NOT NULL,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  established_at TIMESTAMPTZ NOT NULL,
  policy_version VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (health_entry_id)
);

CREATE INDEX IF NOT EXISTS idx_care_establishments_pet_id
  ON care_establishments (pet_id);

CREATE INDEX IF NOT EXISTS idx_care_establishments_pet_family
  ON care_establishments (pet_id, care_family);
