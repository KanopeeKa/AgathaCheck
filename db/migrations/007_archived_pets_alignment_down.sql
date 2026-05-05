-- Rollback for 007_archived_pets_alignment.sql
-- Reverts archived_pets to the v3-era pet-copy shape and restores the
-- pre-007 constraints (CASCADE FK, NOT NULL species/user_id, INTEGER pets.org_id).
--
-- This is a best-effort rollback: it restores column shape and FK behavior,
-- but any data captured under the new transfer-record shape is dropped along
-- with its columns.

BEGIN;

-- pets.organization_id back to INTEGER (NULL-only)
ALTER TABLE pets ALTER COLUMN organization_id TYPE INTEGER USING NULL;

DROP INDEX IF EXISTS idx_archived_pets_organization_id;

ALTER TABLE archived_pets DROP COLUMN IF EXISTS organization_id;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS pet_id;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS pet_name;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS pdf_data;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS transfer_type;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS transferred_to_user_id;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS transferred_to_org_id;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS notes;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS created_at;

ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS name VARCHAR(255);
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS breed VARCHAR(100) DEFAULT '';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS age DOUBLE PRECISION;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS date_of_birth DATE;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS weight DOUBLE PRECISION;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS gender VARCHAR(20);

-- Restore prior NOT NULLs (only safe when no rows violate them — true on empty tables)
ALTER TABLE archived_pets ALTER COLUMN name SET NOT NULL;
ALTER TABLE archived_pets ALTER COLUMN species SET NOT NULL;
ALTER TABLE archived_pets ALTER COLUMN species DROP DEFAULT;
ALTER TABLE archived_pets ALTER COLUMN user_id SET NOT NULL;

-- Restore CASCADE FK
ALTER TABLE archived_pets DROP CONSTRAINT IF EXISTS archived_pets_user_id_fkey;
ALTER TABLE archived_pets
  ADD CONSTRAINT archived_pets_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

COMMIT;
