-- D24 account + absence timezone; absence guest invites and time-bound grants (phase 4)

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS timezone VARCHAR(64) NOT NULL DEFAULT 'UTC';

ALTER TABLE planned_absences
  ADD COLUMN IF NOT EXISTS timezone VARCHAR(64) NOT NULL DEFAULT 'UTC';

CREATE TABLE IF NOT EXISTS planned_absence_carer_invites (
  id                  UUID PRIMARY KEY,
  planned_absence_id  UUID NOT NULL REFERENCES planned_absences(id) ON DELETE CASCADE,
  contact_id          UUID NOT NULL REFERENCES people_contacts(id) ON DELETE CASCADE,
  inviter_user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invitee_email       VARCHAR(255) NOT NULL,
  invitee_user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  code                VARCHAR(32) NOT NULL UNIQUE,
  status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','accepted','declined','revoked','expired')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at        TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS planned_absence_carer_invite_pets (
  invite_id UUID NOT NULL REFERENCES planned_absence_carer_invites(id) ON DELETE CASCADE,
  pet_id    UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  PRIMARY KEY (invite_id, pet_id)
);

CREATE TABLE IF NOT EXISTS planned_absence_guest_grants (
  id                  UUID PRIMARY KEY,
  planned_absence_id  UUID NOT NULL REFERENCES planned_absences(id) ON DELETE CASCADE,
  pet_id              UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  grantee_user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  granted_by_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_id          UUID REFERENCES people_contacts(id) ON DELETE SET NULL,
  invite_id           UUID REFERENCES planned_absence_carer_invites(id) ON DELETE SET NULL,
  status              VARCHAR(20) NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','revoked','expired')),
  revoked_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT planned_absence_guest_grants_unique UNIQUE (planned_absence_id, pet_id, grantee_user_id)
);

CREATE INDEX IF NOT EXISTS idx_pa_carer_invites_absence
  ON planned_absence_carer_invites (planned_absence_id);

CREATE INDEX IF NOT EXISTS idx_pa_carer_invites_invitee_email
  ON planned_absence_carer_invites (lower(invitee_email));

CREATE INDEX IF NOT EXISTS idx_pa_guest_grants_grantee_active
  ON planned_absence_guest_grants (grantee_user_id)
  WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_pa_guest_grants_pet_active
  ON planned_absence_guest_grants (pet_id)
  WHERE status = 'active';
