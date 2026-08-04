-- Phase 8: per-org member privacy columns + named visibility grants.
-- Legacy foster/admin prefs backfill runs in server/scripts/migrations/042_org_member_privacy.js

ALTER TABLE organization_users
  ADD COLUMN IF NOT EXISTS card_visibility TEXT NOT NULL DEFAULT 'all',
  ADD COLUMN IF NOT EXISTS phone_visibility TEXT NOT NULL DEFAULT 'admins_or_named',
  ADD COLUMN IF NOT EXISTS email_visibility TEXT NOT NULL DEFAULT 'admins_or_named',
  ADD COLUMN IF NOT EXISTS address_visibility TEXT NOT NULL DEFAULT 'admins_or_named';

ALTER TABLE organization_users
  DROP CONSTRAINT IF EXISTS organization_users_card_visibility_check;

ALTER TABLE organization_users
  ADD CONSTRAINT organization_users_card_visibility_check
  CHECK (card_visibility IN ('all', 'admins', 'named'));

ALTER TABLE organization_users
  DROP CONSTRAINT IF EXISTS organization_users_phone_visibility_check;

ALTER TABLE organization_users
  ADD CONSTRAINT organization_users_phone_visibility_check
  CHECK (phone_visibility IN (
    'admins', 'admins_and_foster_managers', 'admins_or_named', 'named'
  ));

ALTER TABLE organization_users
  DROP CONSTRAINT IF EXISTS organization_users_email_visibility_check;

ALTER TABLE organization_users
  ADD CONSTRAINT organization_users_email_visibility_check
  CHECK (email_visibility IN (
    'admins', 'admins_and_foster_managers', 'admins_or_named', 'named'
  ));

ALTER TABLE organization_users
  DROP CONSTRAINT IF EXISTS organization_users_address_visibility_check;

ALTER TABLE organization_users
  ADD CONSTRAINT organization_users_address_visibility_check
  CHECK (address_visibility IN (
    'admins_or_named', 'admins', 'named', 'hidden'
  ));

CREATE TABLE IF NOT EXISTS organization_visibility_grants (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  subject_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  grantee_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  field TEXT NOT NULL CHECK (field IN ('card', 'phone', 'email', 'address')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, subject_user_id, grantee_user_id, field)
);

CREATE INDEX IF NOT EXISTS idx_org_visibility_grants_subject
  ON organization_visibility_grants (organization_id, subject_user_id);

CREATE INDEX IF NOT EXISTS idx_org_visibility_grants_grantee
  ON organization_visibility_grants (organization_id, grantee_user_id);
