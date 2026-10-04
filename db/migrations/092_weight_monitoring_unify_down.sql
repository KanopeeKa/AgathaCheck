-- Down: converted lb values are not restored (kg is correct data).

BEGIN;

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_weight_unit_check;
ALTER TABLE users DROP COLUMN IF EXISTS weight_unit;

ALTER TABLE weight_entries DROP CONSTRAINT IF EXISTS weight_entries_unit_kg_check;
ALTER TABLE weight_entries ALTER COLUMN date DROP NOT NULL;
ALTER TABLE weight_entries ALTER COLUMN unit DROP NOT NULL;

COMMIT;
