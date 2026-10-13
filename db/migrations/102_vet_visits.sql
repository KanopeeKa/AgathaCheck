-- PR-14: vet visit records + links to health occurrences (schema/API slice; no UI)

CREATE TABLE IF NOT EXISTS vet_visits (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  visited_on date NOT NULL,
  status character varying(32) NOT NULL DEFAULT 'open',
  completed_on date,
  notes text NOT NULL DEFAULT '',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamp with time zone NOT NULL DEFAULT NOW(),
  updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
  CONSTRAINT vet_visits_status_check
    CHECK (status IN ('open', 'completed')),
  CONSTRAINT vet_visits_completed_on_check
    CHECK (
      (status = 'completed' AND completed_on IS NOT NULL)
      OR (status = 'open' AND completed_on IS NULL)
    )
);

CREATE INDEX IF NOT EXISTS vet_visits_pet_visited_idx
  ON vet_visits (pet_id, visited_on DESC);

CREATE TABLE IF NOT EXISTS vet_visit_occurrence_links (
  id UUID PRIMARY KEY,
  vet_visit_id UUID NOT NULL REFERENCES vet_visits(id) ON DELETE CASCADE,
  health_occurrence_id UUID NOT NULL REFERENCES health_occurrences(id) ON DELETE CASCADE,
  created_at timestamp with time zone NOT NULL DEFAULT NOW(),
  CONSTRAINT vet_visit_occurrence_links_unique_occurrence
    UNIQUE (health_occurrence_id)
);

CREATE INDEX IF NOT EXISTS vet_visit_occurrence_links_visit_idx
  ON vet_visit_occurrence_links (vet_visit_id);
