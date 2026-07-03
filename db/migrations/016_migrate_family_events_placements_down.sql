-- Rollback for 016_migrate_family_events_placements.sql
-- Removes only rows created by the migration (tagged in notes).

DELETE FROM foster_placements
WHERE notes LIKE '%[migrated from family_events]%';
