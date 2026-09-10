-- CC-1: Care Context planned absence (declarer-scoped personal context)

CREATE TABLE IF NOT EXISTS planned_absences (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  starts_on DATE NOT NULL,
  ends_on DATE NOT NULL,
  provenance VARCHAR(50) NOT NULL DEFAULT 'user_declared',
  source_ref TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  cancelled_at TIMESTAMPTZ,
  CONSTRAINT planned_absences_date_order CHECK (ends_on >= starts_on)
);

CREATE INDEX IF NOT EXISTS idx_planned_absences_user_starts
  ON planned_absences (user_id, starts_on ASC);

CREATE TABLE IF NOT EXISTS planned_absence_pets (
  planned_absence_id UUID NOT NULL REFERENCES planned_absences(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  PRIMARY KEY (planned_absence_id, pet_id)
);

CREATE INDEX IF NOT EXISTS idx_planned_absence_pets_pet
  ON planned_absence_pets (pet_id);
