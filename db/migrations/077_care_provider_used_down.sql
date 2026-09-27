DROP INDEX IF EXISTS idx_health_occurrences_provider_contact_id;

ALTER TABLE health_occurrences
  DROP COLUMN IF EXISTS provider_contact_snapshot,
  DROP COLUMN IF EXISTS provider_typed_name,
  DROP COLUMN IF EXISTS provider_contact_id;

ALTER TABLE health_entries
  DROP COLUMN IF EXISTS provider_typed_name;
