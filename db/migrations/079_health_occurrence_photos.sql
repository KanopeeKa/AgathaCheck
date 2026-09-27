-- Link care item documents to a specific occurrence (Care Item evolution phase C).

ALTER TABLE health_event_photos
  ADD COLUMN IF NOT EXISTS health_occurrence_id UUID
  REFERENCES health_occurrences(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_health_event_photos_occurrence
  ON health_event_photos (health_occurrence_id)
  WHERE health_occurrence_id IS NOT NULL;
