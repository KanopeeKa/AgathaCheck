-- Email-based pet share invites (multi-pet capable)

CREATE TABLE IF NOT EXISTS pet_share_invites (
  id               UUID PRIMARY KEY,
  inviter_user_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invitee_email    VARCHAR(255) NOT NULL,
  invitee_user_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  role             VARCHAR(20) NOT NULL CHECK (role IN ('carer', 'co_parent')),
  code             VARCHAR(32) NOT NULL UNIQUE,
  status           VARCHAR(20) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending','accepted','declined','revoked','expired')),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  responded_at     TIMESTAMPTZ,
  expires_at       TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS pet_share_invite_pets (
  invite_id  UUID NOT NULL REFERENCES pet_share_invites(id) ON DELETE CASCADE,
  pet_id     UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  PRIMARY KEY (invite_id, pet_id)
);

CREATE INDEX IF NOT EXISTS idx_pet_share_invites_invitee_user_id
  ON pet_share_invites (invitee_user_id) WHERE invitee_user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_pet_share_invites_invitee_email
  ON pet_share_invites (lower(invitee_email));

CREATE INDEX IF NOT EXISTS idx_pet_share_invite_pets_pet_id
  ON pet_share_invite_pets (pet_id);
