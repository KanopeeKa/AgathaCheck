-- People s5: household-directory notes per contact (I10).

CREATE TABLE IF NOT EXISTS people_contact_household_notes (
  contact_id          UUID NOT NULL REFERENCES people_contacts(id) ON DELETE CASCADE,
  household_id        UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  note                TEXT NOT NULL DEFAULT '',
  updated_by_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (contact_id, household_id)
);

CREATE INDEX IF NOT EXISTS idx_people_contact_household_notes_household
  ON people_contact_household_notes (household_id);
