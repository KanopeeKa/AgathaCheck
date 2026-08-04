-- Rollback Phase 8 member privacy (best-effort).

DROP TABLE IF EXISTS organization_visibility_grants;

ALTER TABLE organization_users
  DROP CONSTRAINT IF EXISTS organization_users_card_visibility_check,
  DROP CONSTRAINT IF EXISTS organization_users_phone_visibility_check,
  DROP CONSTRAINT IF EXISTS organization_users_email_visibility_check,
  DROP CONSTRAINT IF EXISTS organization_users_address_visibility_check;

ALTER TABLE organization_users
  DROP COLUMN IF EXISTS card_visibility,
  DROP COLUMN IF EXISTS phone_visibility,
  DROP COLUMN IF EXISTS email_visibility,
  DROP COLUMN IF EXISTS address_visibility;
