-- Care recommendation persistence for Phase C crisp-rule suggestions.
CREATE TABLE IF NOT EXISTS care_recommendations (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  care_family VARCHAR(50) NOT NULL,
  suggestion_key VARCHAR(100) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  engine_version VARCHAR(20) NOT NULL,
  knowledge_version VARCHAR(20) NOT NULL,
  suggested_name VARCHAR(255) NOT NULL,
  suggested_frequency VARCHAR(30) NOT NULL,
  suggested_frequency_interval INTEGER NOT NULL DEFAULT 1,
  suggested_health_entry_type VARCHAR(30) NOT NULL DEFAULT 'other',
  rationale_key VARCHAR(100) NOT NULL,
  health_entry_id UUID REFERENCES health_entries(id) ON DELETE SET NULL,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS care_recommendations_pet_family_key_idx
  ON care_recommendations (pet_id, care_family, suggestion_key);

CREATE INDEX IF NOT EXISTS care_recommendations_pet_status_idx
  ON care_recommendations (pet_id, status);
