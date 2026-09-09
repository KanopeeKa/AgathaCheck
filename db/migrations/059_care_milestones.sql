-- CP-4: durable care milestones and per-user presentation tracking

CREATE TABLE IF NOT EXISTS care_milestones (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  milestone_type VARCHAR(50) NOT NULL,
  care_family VARCHAR(50),
  source_entity_id UUID,
  care_period_key VARCHAR(50),
  dedupe_key VARCHAR(100) NOT NULL,
  achieved_at TIMESTAMPTZ NOT NULL,
  policy_version VARCHAR(20) NOT NULL,
  bundle_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (pet_id, dedupe_key)
);

CREATE INDEX IF NOT EXISTS idx_care_milestones_pet_id
  ON care_milestones (pet_id);

CREATE INDEX IF NOT EXISTS idx_care_milestones_pet_bundle
  ON care_milestones (pet_id, bundle_id);

CREATE TABLE IF NOT EXISTS care_milestone_presentations (
  id UUID PRIMARY KEY,
  milestone_id UUID NOT NULL REFERENCES care_milestones(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shown_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (milestone_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_care_milestone_presentations_user
  ON care_milestone_presentations (user_id, shown_at DESC);
