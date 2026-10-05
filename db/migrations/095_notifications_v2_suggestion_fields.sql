-- Notifications v2 PR5: suggestion inbox columns + active dedupe index.

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS suggestion_dedupe_key VARCHAR(255);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS suggestion_state VARCHAR(32) DEFAULT 'new';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS suggestion_confidence NUMERIC(4, 3);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS suggestion_expires_at TIMESTAMPTZ;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS suggestion_payload JSONB;

CREATE UNIQUE INDEX IF NOT EXISTS idx_notifications_suggestion_dedupe_active
  ON notifications (user_id, suggestion_dedupe_key)
  WHERE kind = 'suggestion'
    AND archived_at IS NULL
    AND suggestion_state IN ('new', 'seen');
