-- Consolidate health_entries.type to four canonical values (W06).
-- Maps legacy family_event and procedure rows to other.
-- Does not touch organisation family_events (foster/placement).

UPDATE health_entries
SET type = 'other', updated_at = NOW()
WHERE type IN ('family_event', 'procedure');
