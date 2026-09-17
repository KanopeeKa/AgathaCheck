-- Allow non-UUID reference ids in notifications (e.g. share invite codes).

ALTER TABLE notifications
  ALTER COLUMN health_entry_id TYPE VARCHAR(255)
  USING health_entry_id::text;
