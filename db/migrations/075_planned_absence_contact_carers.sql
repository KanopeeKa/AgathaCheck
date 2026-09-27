-- People phase 2: contact-backed absence carers (D28, amends-away-planning)

ALTER TABLE planned_absence_pets
  ADD COLUMN IF NOT EXISTS contact_id UUID REFERENCES people_contacts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_planned_absence_pets_contact_id
  ON planned_absence_pets (contact_id)
  WHERE contact_id IS NOT NULL;
