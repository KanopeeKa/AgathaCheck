-- Care Item evolution phase E: per-item absence resolutions (D-CIE-012, D-CIE-013).

CREATE TABLE IF NOT EXISTS health_entry_absence_resolutions (
  id UUID PRIMARY KEY,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  planned_absence_id UUID NOT NULL REFERENCES planned_absences(id) ON DELETE CASCADE,
  decision TEXT NOT NULL,
  carer_kind TEXT,
  carer_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  carer_name TEXT,
  absence_note TEXT,
  dates_decided_for JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (health_entry_id, planned_absence_id)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_entry_absence_resolutions_decision_check'
  ) THEN
    ALTER TABLE health_entry_absence_resolutions
      ADD CONSTRAINT health_entry_absence_resolutions_decision_check CHECK (
        decision IN ('keep_date', 'move_before', 'move_after', 'nothing_needed')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_entry_absence_resolutions_carer_kind_check'
  ) THEN
    ALTER TABLE health_entry_absence_resolutions
      ADD CONSTRAINT health_entry_absence_resolutions_carer_kind_check CHECK (
        carer_kind IS NULL OR carer_kind IN ('shared_user', 'note_only')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'health_entry_absence_resolutions_carer_fields_check'
  ) THEN
    ALTER TABLE health_entry_absence_resolutions
      ADD CONSTRAINT health_entry_absence_resolutions_carer_fields_check CHECK (
        (
          carer_kind IS NULL
          AND carer_user_id IS NULL
          AND carer_name IS NULL
        )
        OR (
          carer_kind = 'shared_user'
          AND carer_name IS NULL
        )
        OR (
          carer_kind = 'note_only'
          AND carer_user_id IS NULL
          AND carer_name IS NOT NULL
        )
      );
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_health_entry_absence_resolutions_absence
  ON health_entry_absence_resolutions (planned_absence_id);

CREATE INDEX IF NOT EXISTS idx_health_entry_absence_resolutions_entry
  ON health_entry_absence_resolutions (health_entry_id);
