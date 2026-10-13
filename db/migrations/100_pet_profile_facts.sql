-- PR-01: profile identification / neuter status facts on pets

ALTER TABLE pets
  ADD COLUMN IF NOT EXISTS identification_status character varying(16) NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS neuter_status character varying(16) NOT NULL DEFAULT 'unknown',
  ADD COLUMN IF NOT EXISTS identification_status_source character varying(64),
  ADD COLUMN IF NOT EXISTS neuter_status_source character varying(64),
  ADD COLUMN IF NOT EXISTS identification_status_updated_at timestamp with time zone,
  ADD COLUMN IF NOT EXISTS neuter_status_updated_at timestamp with time zone;

ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_identification_status_check;

ALTER TABLE pets
  ADD CONSTRAINT pets_identification_status_check
  CHECK (identification_status IN ('yes', 'no', 'unknown'));

ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_neuter_status_check;

ALTER TABLE pets
  ADD CONSTRAINT pets_neuter_status_check
  CHECK (neuter_status IN ('yes', 'no', 'unknown'));

UPDATE pets
SET identification_status = 'yes'
WHERE identification_status = 'unknown'
  AND chip_id IS NOT NULL
  AND TRIM(chip_id) <> '';

UPDATE pets
SET neuter_status = 'yes'
WHERE neuter_status = 'unknown'
  AND neutered_date IS NOT NULL;
