-- Reverse care item Closed migration (dev only).

BEGIN;

DROP TRIGGER IF EXISTS health_entries_normalize_closed_status ON health_entries;
DROP FUNCTION IF EXISTS health_entries_normalize_closed_status();

ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_closed_reason_required;
ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_care_closed_reason_check;
ALTER TABLE health_entries DROP CONSTRAINT IF EXISTS health_entries_status_check;

ALTER TABLE health_entries DROP COLUMN IF EXISTS care_closed_reason;

ALTER TABLE health_entries
  ADD CONSTRAINT health_entries_status_check CHECK (
    status IN ('active', 'paused', 'completed')
  );

COMMIT;
