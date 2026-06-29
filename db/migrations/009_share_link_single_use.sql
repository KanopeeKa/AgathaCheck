-- Single-use share links: status tracking and pet_access linkage.

BEGIN;

ALTER TABLE pet_share_links
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS claimed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ;

ALTER TABLE pet_access
  ADD COLUMN IF NOT EXISTS share_link_id UUID REFERENCES pet_share_links(id) ON DELETE SET NULL;

-- One-step sharing: upgrade any legacy pending invitations.
UPDATE pet_access SET role = 'shared', updated_at = NOW() WHERE role = 'pending_shared';

CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_access_pet_user ON pet_access(pet_id, user_id);

COMMIT;
