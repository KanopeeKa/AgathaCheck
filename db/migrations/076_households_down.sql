DROP TABLE IF EXISTS pet_access_events;

ALTER TABLE people_directories DROP CONSTRAINT IF EXISTS people_directories_owner_xor_household;
DROP INDEX IF EXISTS people_directories_household_unique;
DROP INDEX IF EXISTS people_directories_owner_user_unique;

ALTER TABLE people_directories DROP COLUMN IF EXISTS household_id;

ALTER TABLE people_directories
  ALTER COLUMN owner_user_id SET NOT NULL;

ALTER TABLE people_directories
  ADD CONSTRAINT people_directories_owner_user_unique UNIQUE (owner_user_id);

DROP TABLE IF EXISTS household_pets;
DROP TABLE IF EXISTS household_members;
DROP TABLE IF EXISTS households;
