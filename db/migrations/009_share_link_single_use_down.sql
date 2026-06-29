BEGIN;

DROP INDEX IF EXISTS idx_pet_access_pet_user;

ALTER TABLE pet_access DROP COLUMN IF EXISTS share_link_id;

ALTER TABLE pet_share_links
  DROP COLUMN IF EXISTS claimed_at,
  DROP COLUMN IF EXISTS claimed_by,
  DROP COLUMN IF EXISTS status;

COMMIT;
