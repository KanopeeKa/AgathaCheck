-- People s6: optional contact link on pet share invites

ALTER TABLE pet_share_invites
  ADD COLUMN IF NOT EXISTS contact_id UUID REFERENCES people_contacts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_pet_share_invites_contact_id
  ON pet_share_invites (contact_id)
  WHERE contact_id IS NOT NULL;
