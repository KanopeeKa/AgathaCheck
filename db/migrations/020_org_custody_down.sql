BEGIN;

DROP TABLE IF EXISTS org_pet_home_hidden;
DROP TABLE IF EXISTS custody_transfers;
DROP TABLE IF EXISTS org_connection_requests;
DROP TABLE IF EXISTS org_connections;

ALTER TABLE archived_pets DROP COLUMN IF EXISTS shadow_snapshot;
ALTER TABLE archived_pets DROP COLUMN IF EXISTS frozen_at;

ALTER TABLE pets DROP COLUMN IF EXISTS care_holder_kind;
ALTER TABLE pets DROP COLUMN IF EXISTS care_holder_user_id;
ALTER TABLE pets DROP COLUMN IF EXISTS care_holder_org_id;

COMMIT;
