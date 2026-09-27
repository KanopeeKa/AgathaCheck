BEGIN;

ALTER TABLE health_entries
  DROP COLUMN IF EXISTS care_blocks;

COMMIT;
