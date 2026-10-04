-- Weight monitoring unify (W1): kg-only storage, required dates, user weight_unit preference.

BEGIN;

DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM weight_entries
    WHERE unit IS NOT NULL AND lower(unit) NOT IN ('kg', 'lb', 'lbs')
  ) THEN
    RAISE EXCEPTION 'weight_entries has units other than kg/lb; convert manually first';
  END IF;
END $$;

UPDATE weight_entries
SET weight = weight * 0.45359237, unit = 'kg'
WHERE lower(unit) IN ('lb', 'lbs');

UPDATE weight_entries SET unit = 'kg' WHERE unit IS NULL;

UPDATE weight_entries
SET date = (COALESCE(measured_at, created_at) AT TIME ZONE 'UTC')::date
WHERE date IS NULL;

UPDATE weight_entries SET date = CURRENT_DATE WHERE date IS NULL;

ALTER TABLE weight_entries
  ALTER COLUMN unit SET DEFAULT 'kg',
  ALTER COLUMN unit SET NOT NULL,
  ALTER COLUMN date SET NOT NULL;

ALTER TABLE weight_entries
  ADD CONSTRAINT weight_entries_unit_kg_check CHECK (unit = 'kg');

ALTER TABLE users
  ADD COLUMN weight_unit varchar(2) NOT NULL DEFAULT 'kg';

ALTER TABLE users
  ADD CONSTRAINT users_weight_unit_check CHECK (weight_unit IN ('kg', 'lb'));

COMMIT;
