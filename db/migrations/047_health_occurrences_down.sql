BEGIN;

DROP TABLE IF EXISTS health_occurrences CASCADE;

ALTER TABLE health_entries DROP COLUMN IF EXISTS schedule_times;

COMMIT;
