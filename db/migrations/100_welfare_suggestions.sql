-- PR-06: welfare guidance (separate from care_recommendations / rhythm).

CREATE TABLE IF NOT EXISTS welfare_suggestions (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  subject_key VARCHAR(100) NOT NULL,
  dedupe_key VARCHAR(200) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending',
  primary_outcome VARCHAR(100),
  rationale_key VARCHAR(100) NOT NULL,
  engine_version VARCHAR(20) NOT NULL,
  severity INTEGER NOT NULL DEFAULT 0,
  dismissed_until TIMESTAMPTZ,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS welfare_suggestions_pet_dedupe_idx
  ON welfare_suggestions (pet_id, dedupe_key);

CREATE INDEX IF NOT EXISTS welfare_suggestions_pet_status_idx
  ON welfare_suggestions (pet_id, status);
