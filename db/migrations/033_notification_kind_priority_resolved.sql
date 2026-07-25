-- Phase 0: notification kind, priority, resolved_at (experience-program program-contract §3.1)

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS kind VARCHAR(16) NOT NULL DEFAULT 'care';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS priority VARCHAR(8) NOT NULL DEFAULT 'normal';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_kind_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_kind_check
  CHECK (kind IN ('care', 'administrative'));

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_priority_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_priority_check
  CHECK (priority IN ('normal', 'urgent'));
