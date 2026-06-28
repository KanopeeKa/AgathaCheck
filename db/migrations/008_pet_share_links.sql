-- Pet sharing: share-link persistence and invited_by on pet_access.

BEGIN;

CREATE TABLE IF NOT EXISTS pet_share_links (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  code VARCHAR(32) UNIQUE NOT NULL,
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pet_share_links_pet_id ON pet_share_links(pet_id);
CREATE INDEX IF NOT EXISTS idx_pet_share_links_code ON pet_share_links(code);

ALTER TABLE pet_access ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES users(id) ON DELETE SET NULL;

COMMIT;
