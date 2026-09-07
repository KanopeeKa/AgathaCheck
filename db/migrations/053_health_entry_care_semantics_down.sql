ALTER TABLE health_entries
  DROP COLUMN IF EXISTS care_family,
  DROP COLUMN IF EXISTS care_source;
