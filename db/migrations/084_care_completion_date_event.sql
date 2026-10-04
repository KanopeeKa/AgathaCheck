-- Care occurrences C0 (D-CSM-034): ledger event for changing when a
-- completed occurrence was done, so the change can be undone.

BEGIN;

ALTER TABLE care_schedule_events
  DROP CONSTRAINT IF EXISTS care_schedule_events_event_type_check;

ALTER TABLE care_schedule_events
  ADD CONSTRAINT care_schedule_events_event_type_check CHECK (
    event_type IN (
      'rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted',
      'completed', 'postponed', 'materialised', 'late_choice_applied',
      'not_recorded_closed', 'schedule_scope_changed', 'planned', 'recorded',
      'stack_resolved', 'undone', 'schedule_changed', 'completion_date_changed'
    )
  );

COMMIT;
