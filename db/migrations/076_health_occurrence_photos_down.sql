DROP INDEX IF EXISTS idx_health_event_photos_occurrence;

ALTER TABLE health_event_photos DROP COLUMN IF EXISTS health_occurrence_id;
