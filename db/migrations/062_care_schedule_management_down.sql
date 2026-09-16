ALTER TABLE health_occurrences
  DROP CONSTRAINT IF EXISTS health_occurrences_completion_timing_check;

ALTER TABLE health_occurrences
  DROP COLUMN IF EXISTS completion_timing;

ALTER TABLE health_entries
  DROP COLUMN IF EXISTS schedule_policy_version;

ALTER TABLE health_entries
  DROP COLUMN IF EXISTS paused_since;

DROP INDEX IF EXISTS idx_care_schedule_events_occurrence;
DROP INDEX IF EXISTS idx_care_schedule_events_entry_occurred;
DROP INDEX IF EXISTS idx_care_schedule_events_idempotency;
DROP TABLE IF EXISTS care_schedule_events;
