DROP INDEX IF EXISTS idx_pet_share_invites_contact_id;

ALTER TABLE pet_share_invites
  DROP COLUMN IF EXISTS contact_id;
