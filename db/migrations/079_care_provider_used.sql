-- Care Item evolution phase D: typed provider on items; provider used on occurrences (D-CIE-016, D-CIE-020).

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS provider_typed_name TEXT;

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS provider_contact_id UUID
    REFERENCES people_contacts(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS provider_typed_name TEXT,
  ADD COLUMN IF NOT EXISTS provider_contact_snapshot JSONB;

CREATE INDEX IF NOT EXISTS idx_health_occurrences_provider_contact_id
  ON health_occurrences (provider_contact_id)
  WHERE provider_contact_id IS NOT NULL;
