-- Migration: Switch users.id and all user_id references to UUID
-- Enable uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Change users.id to UUID
ALTER TABLE users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE users ALTER COLUMN id TYPE UUID USING uuid_generate_v4();
ALTER TABLE users ALTER COLUMN id SET DEFAULT uuid_generate_v4();

-- Update all referencing tables
ALTER TABLE refresh_tokens ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE password_reset_tokens ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE pet_access ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE shared_pets ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE pets ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE vets ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
ALTER TABLE organization_users ALTER COLUMN user_id TYPE UUID USING user_id::uuid;
-- Add more as needed for your schema

-- Update all foreign key constraints
ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_user_id_fkey;
ALTER TABLE refresh_tokens ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE password_reset_tokens DROP CONSTRAINT IF EXISTS password_reset_tokens_user_id_fkey;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE pet_access DROP CONSTRAINT IF EXISTS pet_access_user_id_fkey;
ALTER TABLE pet_access ADD CONSTRAINT pet_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE shared_pets DROP CONSTRAINT IF EXISTS shared_pets_user_id_fkey;
ALTER TABLE shared_pets ADD CONSTRAINT shared_pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE pets DROP CONSTRAINT IF EXISTS pets_user_id_fkey;
ALTER TABLE pets ADD CONSTRAINT pets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE vets DROP CONSTRAINT IF EXISTS vets_user_id_fkey;
ALTER TABLE vets ADD CONSTRAINT vets_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE organization_users DROP CONSTRAINT IF EXISTS organization_users_user_id_fkey;
ALTER TABLE organization_users ADD CONSTRAINT organization_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Repeat for all other referencing tables

-- Note: You may need to update triggers, indexes, and other constraints as well.

-- Test: Insert a user and reference it from other tables.

-- Rollback: You can revert to integer if needed, but will lose UUIDs.

-- End migration
