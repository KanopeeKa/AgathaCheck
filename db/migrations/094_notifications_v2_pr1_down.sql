-- Best-effort down: drop archive column and restore two-kind constraint.
-- Does not restore archived rows or reverted type/kind values.

DROP INDEX IF EXISTS idx_notifications_user_inbox_active;

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_kind_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_kind_check
  CHECK (kind IN ('care', 'administrative'));

UPDATE notifications SET kind = 'care'
WHERE kind IN ('relationship', 'suggestion', 'account');

ALTER TABLE notifications DROP COLUMN IF EXISTS archived_at;
