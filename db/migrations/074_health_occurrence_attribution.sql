-- People phase 1: provider on care items; performed/logged snapshots on occurrences.

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS provider_contact_id UUID
    REFERENCES people_contacts(id) ON DELETE SET NULL;

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS performed_by_user_id UUID
    REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS performed_by_snapshot JSONB,
  ADD COLUMN IF NOT EXISTS marked_by_snapshot JSONB;

CREATE INDEX IF NOT EXISTS idx_health_entries_provider_contact_id
  ON health_entries (provider_contact_id)
  WHERE provider_contact_id IS NOT NULL;
