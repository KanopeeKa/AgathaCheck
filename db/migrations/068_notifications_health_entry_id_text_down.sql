-- Revert only when no non-UUID health_entry_id values exist.
ALTER TABLE notifications
  ALTER COLUMN health_entry_id TYPE UUID
  USING NULLIF(health_entry_id, '')::uuid;
