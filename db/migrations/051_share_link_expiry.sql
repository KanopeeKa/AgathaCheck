-- F-04: share link expiry column
ALTER TABLE pet_share_links
  ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_pet_share_links_expires_at
  ON pet_share_links (expires_at)
  WHERE status = 'pending';
