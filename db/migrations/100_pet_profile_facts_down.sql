ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_identification_status_check,
  DROP CONSTRAINT IF EXISTS pets_neuter_status_check;

ALTER TABLE pets
  DROP COLUMN IF EXISTS identification_status,
  DROP COLUMN IF EXISTS neuter_status,
  DROP COLUMN IF EXISTS identification_status_source,
  DROP COLUMN IF EXISTS neuter_status_source,
  DROP COLUMN IF EXISTS identification_status_updated_at,
  DROP COLUMN IF EXISTS neuter_status_updated_at;
