-- Care occurrences programme (D-CSM-019 … D-CSM-033): occurrence origins and
-- close reasons, Fixed-schedule anchor, remembered next-date choice,
-- postpone-until, and a ledger payload for whole-command undo.
-- Existing rows are adjusted by the JS hook (083_care_occurrence_model.js).

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS origin VARCHAR(16) NOT NULL DEFAULT 'computed';

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS close_reason VARCHAR(16);

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS series_date DATE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_occurrences_origin_check'
  ) THEN
    ALTER TABLE health_occurrences
      ADD CONSTRAINT health_occurrences_origin_check CHECK (
        origin IN ('schedule', 'computed', 'planned')
      );
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_occurrences_close_reason_check'
  ) THEN
    ALTER TABLE health_occurrences
      ADD CONSTRAINT health_occurrences_close_reason_check CHECK (
        close_reason IS NULL
        OR close_reason IN ('user', 'not_recorded', 'paused', 'covered', 'system')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_health_occurrences_entry_series_slot
  ON health_occurrences (health_entry_id, (COALESCE(series_date, scheduled_date)));

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS schedule_anchor_date DATE;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS late_completion_choice VARCHAR(16);

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS paused_until DATE;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS series_resumed_on DATE;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_entries_late_completion_choice_check'
  ) THEN
    ALTER TABLE health_entries
      ADD CONSTRAINT health_entries_late_completion_choice_check CHECK (
        late_completion_choice IS NULL
        OR late_completion_choice IN ('keep', 'skip_next', 'shift_following')
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_health_entries_care_tick
  ON health_entries (status, recurrence_anchor)
  WHERE status IN ('active', 'paused');

ALTER TABLE care_schedule_events
  ADD COLUMN IF NOT EXISTS payload JSONB;

ALTER TABLE care_schedule_events
  ADD COLUMN IF NOT EXISTS undone_at TIMESTAMPTZ;

ALTER TABLE care_schedule_events
  DROP CONSTRAINT IF EXISTS care_schedule_events_event_type_check;

ALTER TABLE care_schedule_events
  ADD CONSTRAINT care_schedule_events_event_type_check CHECK (
    event_type IN (
      'rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted',
      'completed', 'postponed', 'materialised', 'late_choice_applied',
      'not_recorded_closed', 'schedule_scope_changed', 'planned', 'recorded',
      'stack_resolved', 'undone', 'schedule_changed'
    )
  );
