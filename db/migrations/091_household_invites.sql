-- People s6: household email invites (pattern: planned_absence_carer_invites)

CREATE TABLE IF NOT EXISTS household_invites (
  id               UUID PRIMARY KEY,
  household_id     UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  inviter_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invitee_email    VARCHAR(255) NOT NULL,
  invitee_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  access_tier      TEXT NOT NULL CHECK (access_tier IN ('full_access', 'can_log_care')),
  is_organiser     BOOLEAN NOT NULL DEFAULT false,
  contact_id       UUID REFERENCES people_contacts(id) ON DELETE SET NULL,
  code             VARCHAR(32) NOT NULL UNIQUE,
  status           VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','accepted','declined','revoked','expired')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at     TIMESTAMPTZ,
  expires_at       TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_household_invites_household_id
  ON household_invites (household_id);

CREATE INDEX IF NOT EXISTS idx_household_invites_invitee_email
  ON household_invites (lower(invitee_email));

CREATE INDEX IF NOT EXISTS idx_household_invites_invitee_user_id
  ON household_invites (invitee_user_id)
  WHERE invitee_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_household_invites_contact_id
  ON household_invites (contact_id)
  WHERE contact_id IS NOT NULL;
