-- Organisation v2: product activity log for last-activity sorting (D-v2-ACT-1).
-- No backfill — existing pets use COALESCE(last_activity_at, created_at).

CREATE TABLE IF NOT EXISTS pet_activity_events (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL
    CHECK (event_type IN ('health_log', 'foster_session', 'profile_edit', 'document_upload')),
  actor_user_id UUID NULL REFERENCES users(id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NOT NULL DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_pet_activity_events_pet_id
  ON pet_activity_events (pet_id);

CREATE INDEX IF NOT EXISTS idx_pet_activity_events_org_id
  ON pet_activity_events (org_id);

CREATE INDEX IF NOT EXISTS idx_pet_activity_events_occurred_at
  ON pet_activity_events (occurred_at);

ALTER TABLE pets
  ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ NULL;
