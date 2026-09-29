BEGIN;

ALTER TABLE care_schedule_events
  DROP CONSTRAINT IF EXISTS care_schedule_events_event_type_check;

DELETE FROM care_schedule_events
  WHERE event_type NOT IN ('rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted');

ALTER TABLE care_schedule_events
  ADD CONSTRAINT care_schedule_events_event_type_check CHECK (
    event_type IN ('rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted')
  );

ALTER TABLE care_schedule_events DROP COLUMN IF EXISTS undone_at;
ALTER TABLE care_schedule_events DROP COLUMN IF EXISTS payload;

DROP INDEX IF EXISTS idx_health_entries_care_tick;
ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_late_completion_choice_check;
ALTER TABLE health_entries DROP COLUMN IF EXISTS series_resumed_on;
ALTER TABLE health_entries DROP COLUMN IF EXISTS paused_until;
ALTER TABLE health_entries DROP COLUMN IF EXISTS late_completion_choice;
ALTER TABLE health_entries DROP COLUMN IF EXISTS schedule_anchor_date;

DROP INDEX IF EXISTS idx_health_occurrences_entry_series_slot;
ALTER TABLE health_occurrences DROP CONSTRAINT IF EXISTS health_occurrences_close_reason_check;
ALTER TABLE health_occurrences DROP CONSTRAINT IF EXISTS health_occurrences_origin_check;
ALTER TABLE health_occurrences DROP COLUMN IF EXISTS series_date;
ALTER TABLE health_occurrences DROP COLUMN IF EXISTS close_reason;
ALTER TABLE health_occurrences DROP COLUMN IF EXISTS origin;

COMMIT;
