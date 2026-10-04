BEGIN;

ALTER TABLE care_schedule_events
  DROP CONSTRAINT IF EXISTS care_schedule_events_event_type_check;

DELETE FROM care_schedule_events WHERE event_type = 'completion_date_changed';

ALTER TABLE care_schedule_events
  ADD CONSTRAINT care_schedule_events_event_type_check CHECK (
    event_type IN (
      'rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted',
      'completed', 'postponed', 'materialised', 'late_choice_applied',
      'not_recorded_closed', 'schedule_scope_changed', 'planned', 'recorded',
      'stack_resolved', 'undone', 'schedule_changed'
    )
  );

COMMIT;
