DROP INDEX IF EXISTS idx_health_entries_provider_contact_id;

ALTER TABLE health_occurrences
  DROP COLUMN IF EXISTS marked_by_snapshot,
  DROP COLUMN IF EXISTS performed_by_snapshot,
  DROP COLUMN IF EXISTS performed_by_user_id;

ALTER TABLE health_entries
  DROP COLUMN IF EXISTS provider_contact_id;
