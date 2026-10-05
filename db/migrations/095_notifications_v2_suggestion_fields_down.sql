-- Best-effort down: drop suggestion columns and dedupe index.

DROP INDEX IF EXISTS idx_notifications_suggestion_dedupe_active;

ALTER TABLE notifications DROP COLUMN IF EXISTS suggestion_payload;
ALTER TABLE notifications DROP COLUMN IF EXISTS suggestion_expires_at;
ALTER TABLE notifications DROP COLUMN IF EXISTS suggestion_confidence;
ALTER TABLE notifications DROP COLUMN IF EXISTS suggestion_state;
ALTER TABLE notifications DROP COLUMN IF EXISTS suggestion_dedupe_key;
