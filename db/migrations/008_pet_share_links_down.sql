BEGIN;

DROP INDEX IF EXISTS idx_pet_share_links_code;
DROP INDEX IF EXISTS idx_pet_share_links_pet_id;
DROP TABLE IF EXISTS pet_share_links;
ALTER TABLE pet_access DROP COLUMN IF EXISTS invited_by;

COMMIT;
