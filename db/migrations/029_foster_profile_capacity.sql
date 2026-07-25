-- J2 Ph3 / G0 §5.1–5.2: foster profile capacity and competency fields.

ALTER TABLE foster_profiles
  ADD COLUMN IF NOT EXISTS species_capacities JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS self_declared_competencies JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS confirmed_competencies JSONB NOT NULL DEFAULT '[]'::jsonb;
