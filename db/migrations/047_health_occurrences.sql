-- Health occurrence scheduling: first-class dose instants per health entry series.

BEGIN;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS schedule_times JSONB;

CREATE TABLE IF NOT EXISTS health_occurrences (
  id UUID PRIMARY KEY,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  status VARCHAR(50) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'skipped')),
  completed_on DATE,
  marked_at TIMESTAMPTZ,
  marked_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_occurrences_entry_id
  ON health_occurrences (health_entry_id);

CREATE INDEX IF NOT EXISTS idx_health_occurrences_entry_status_date
  ON health_occurrences (health_entry_id, status, scheduled_date, scheduled_time);

-- One open row per (entry, calendar day, time slot).
CREATE UNIQUE INDEX IF NOT EXISTS idx_health_occurrences_open_slot
  ON health_occurrences (
    health_entry_id,
    scheduled_date,
    COALESCE(scheduled_time, '00:00:00'::time)
  )
  WHERE status = 'pending';

COMMIT;
