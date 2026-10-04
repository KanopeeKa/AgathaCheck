CREATE TABLE IF NOT EXISTS pet_lifecycle_notifications (
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  event TEXT NOT NULL,
  recipient_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (pet_id, event, recipient_user_id)
);

CREATE INDEX IF NOT EXISTS idx_pet_lifecycle_notifications_recipient
  ON pet_lifecycle_notifications (recipient_user_id);
