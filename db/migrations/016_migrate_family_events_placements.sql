-- Migrate legacy family_events foster/placement rows into foster_placements (Inc 7).
-- Data rows are inserted by the migration runner (Node/Dart) with application-generated
-- UUIDs — gen_random_uuid() is not available on all deployments.
-- See server/scripts/migrations/016_migrate_family_events_placements.js
-- Idempotent: skips rows that already have a matching foster_placements record.

SELECT 1;
