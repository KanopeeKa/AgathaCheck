-- CP-2: link weight observations to health occurrences (transactional completion)

ALTER TABLE weight_entries
  ADD COLUMN IF NOT EXISTS health_occurrence_id UUID NULL
  REFERENCES health_occurrences(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_weight_entries_health_occurrence_id
  ON weight_entries (health_occurrence_id)
  WHERE health_occurrence_id IS NOT NULL;
