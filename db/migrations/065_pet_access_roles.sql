-- Pet sharing roles: shared -> carer, introduce co_parent, link target role

UPDATE pet_access SET role = 'carer' WHERE role = 'shared';
UPDATE pet_access SET role = 'carer' WHERE role = 'guardian';
UPDATE pet_access SET role = 'carer' WHERE role = 'pending_shared';

ALTER TABLE pet_share_links
  ADD COLUMN IF NOT EXISTS access_role character varying(32) DEFAULT 'carer' NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'pet_share_links_access_role_check'
  ) THEN
    ALTER TABLE pet_share_links
      ADD CONSTRAINT pet_share_links_access_role_check CHECK (
        access_role IN ('carer', 'co_parent')
      );
  END IF;
END $$;

DROP TABLE IF EXISTS shared_pets;
