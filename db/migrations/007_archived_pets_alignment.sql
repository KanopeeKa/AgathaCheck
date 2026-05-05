-- Align dev/legacy schemas with canonical v3 + the actual code.
--
-- Two parallel goals:
-- (a) Reshape archived_pets from a generic pet-copy into a transfer record
--     matching the API/Flutter ArchivedPetModel
--     (server/routes/organizations.js + flutter_app/.../archived_pet_model.dart).
-- (b) Repair drift between v3 and the 001–006 incremental migrations:
--       * archived_pets.user_id FK was ON DELETE CASCADE in v3, but canonical
--         v3 (single-source-of-truth) declares ON DELETE SET NULL.
--       * pets.organization_id was added by 002 as INTEGER, but canonical
--         v3 declares it UUID — the application passes UUID strings.
--
-- Safe to run on existing DBs: archived_pets is empty in any environment that
-- hasn't exercised the archive flow, and pets.organization_id is null on every
-- known dev row (no INTEGER values to lose during the type change).

BEGIN;

-- ── archived_pets shape (was: pet copy, becomes: transfer record) ──
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS pet_id UUID;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS pet_name VARCHAR(255) DEFAULT '';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS pdf_data TEXT DEFAULT '';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS transfer_type VARCHAR(50) DEFAULT 'other';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS transferred_to_user_id UUID;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS transferred_to_org_id UUID;
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';
ALTER TABLE archived_pets ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE archived_pets ALTER COLUMN species DROP NOT NULL;
ALTER TABLE archived_pets ALTER COLUMN species SET DEFAULT '';
ALTER TABLE archived_pets ALTER COLUMN user_id DROP NOT NULL;

-- Drop columns no code path uses (safe — empty table)
ALTER TABLE archived_pets DROP COLUMN IF EXISTS name;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS breed;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS age;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS date_of_birth;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS weight;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS gender;

-- archived_pets.user_id FK: align CASCADE -> SET NULL with canonical v3
ALTER TABLE archived_pets DROP CONSTRAINT IF EXISTS archived_pets_user_id_fkey;
ALTER TABLE archived_pets
  ADD CONSTRAINT archived_pets_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_archived_pets_organization_id ON archived_pets(organization_id);

-- ── pets.organization_id INTEGER -> UUID (drift fix from migration 002) ──
-- All existing values are NULL on every known dev DB; cast forces them to NULL
-- explicitly so the column-type change always succeeds.
ALTER TABLE pets ALTER COLUMN organization_id TYPE UUID USING NULL;

COMMIT;
