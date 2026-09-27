DROP INDEX IF EXISTS idx_people_contacts_legacy_vet_id;

ALTER TABLE people_contacts
  DROP COLUMN IF EXISTS legacy_vet_id;
