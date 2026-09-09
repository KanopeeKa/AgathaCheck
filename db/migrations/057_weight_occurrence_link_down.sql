DROP INDEX IF EXISTS idx_weight_entries_health_occurrence_id;

ALTER TABLE weight_entries
  DROP COLUMN IF EXISTS health_occurrence_id;
