ALTER TABLE pet_share_links DROP CONSTRAINT IF EXISTS pet_share_links_access_role_check;
ALTER TABLE pet_share_links DROP COLUMN IF EXISTS access_role;

UPDATE pet_access SET role = 'shared' WHERE role IN ('carer', 'co_parent');
