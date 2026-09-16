-- CSM-1: Care Schedule Management ledger and scheduling columns

CREATE TABLE IF NOT EXISTS care_schedule_events (
  id UUID PRIMARY KEY,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  health_occurrence_id UUID REFERENCES health_occurrences(id) ON DELETE SET NULL,
  event_type VARCHAR(50) NOT NULL,
  from_date DATE,
  to_date DATE,
  from_anchor VARCHAR(50),
  to_anchor VARCHAR(50),
  reason_code VARCHAR(100),
  reason_note TEXT,
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  effective_from DATE,
  idempotency_key VARCHAR(255),
  policy_version VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT care_schedule_events_event_type_check CHECK (
    event_type IN ('rescheduled', 'skipped', 'paused', 'resumed', 'cadence_adjusted')
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_care_schedule_events_idempotency
  ON care_schedule_events (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_care_schedule_events_entry_occurred
  ON care_schedule_events (health_entry_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS idx_care_schedule_events_occurrence
  ON care_schedule_events (health_occurrence_id)
  WHERE health_occurrence_id IS NOT NULL;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS paused_since DATE;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS schedule_policy_version VARCHAR(20);

ALTER TABLE health_occurrences
  ADD COLUMN IF NOT EXISTS completion_timing VARCHAR(20);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_occurrences_completion_timing_check'
  ) THEN
    ALTER TABLE health_occurrences
      ADD CONSTRAINT health_occurrences_completion_timing_check CHECK (
        completion_timing IS NULL
        OR completion_timing IN ('early', 'on_time', 'late')
      );
  END IF;
END $$;
