-- Phase f-categories: structured category blocks on care items (D-CIE-019).

BEGIN;

ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS care_blocks JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMIT;
