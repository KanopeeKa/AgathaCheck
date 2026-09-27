-- People phase 1: link vets to people_contacts and backfill directories (data in JS).

ALTER TABLE people_contacts
  ADD COLUMN IF NOT EXISTS legacy_vet_id UUID UNIQUE
    REFERENCES vets(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_people_contacts_legacy_vet_id
  ON people_contacts (legacy_vet_id)
  WHERE legacy_vet_id IS NOT NULL;
