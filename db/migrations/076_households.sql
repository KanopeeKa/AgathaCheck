-- People phase 3: households, membership tiers, pet membership (D1–D6).

CREATE TABLE IF NOT EXISTS households (
  id          UUID PRIMARY KEY,
  name        TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS household_members (
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  access_tier   TEXT NOT NULL CHECK (access_tier IN ('full_access', 'can_log_care')),
  is_organiser  BOOLEAN NOT NULL DEFAULT false,
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (household_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_household_members_user_id
  ON household_members (user_id);

CREATE TABLE IF NOT EXISTS household_pets (
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  pet_id        UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  added_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (pet_id)
);

CREATE INDEX IF NOT EXISTS idx_household_pets_household_id
  ON household_pets (household_id);

-- Household directories (personal dirs keep owner_user_id; exactly one dir per household).
ALTER TABLE people_directories
  ADD COLUMN IF NOT EXISTS household_id UUID REFERENCES households(id) ON DELETE CASCADE;

ALTER TABLE people_directories
  ALTER COLUMN owner_user_id DROP NOT NULL;

ALTER TABLE people_directories
  DROP CONSTRAINT IF EXISTS people_directories_owner_user_unique;

CREATE UNIQUE INDEX IF NOT EXISTS people_directories_owner_user_unique
  ON people_directories (owner_user_id)
  WHERE owner_user_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS people_directories_household_unique
  ON people_directories (household_id)
  WHERE household_id IS NOT NULL;

ALTER TABLE people_directories
  DROP CONSTRAINT IF EXISTS people_directories_owner_xor_household;

ALTER TABLE people_directories
  ADD CONSTRAINT people_directories_owner_xor_household CHECK (
    (owner_user_id IS NOT NULL AND household_id IS NULL)
    OR (household_id IS NOT NULL AND owner_user_id IS NULL)
  );

-- Who-has-access audit (capped at 100 events per pet in application code — D214).
CREATE TABLE IF NOT EXISTS pet_access_events (
  id              UUID PRIMARY KEY,
  pet_id          UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  subject_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type      TEXT NOT NULL,
  access_source   TEXT NOT NULL CHECK (
    access_source IN ('household', 'direct_share', 'absence', 'owner')
  ),
  detail          JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pet_access_events_pet_created
  ON pet_access_events (pet_id, created_at DESC);
