-- PR-09: structured vaccination history (no summary column on pets)

CREATE TABLE IF NOT EXISTS pet_vaccination_records (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  vaccine_name character varying(255) NOT NULL,
  administered_on date NOT NULL,
  record_source character varying(32) NOT NULL DEFAULT 'user',
  created_by UUID REFERENCES users(id),
  created_at timestamp with time zone NOT NULL DEFAULT NOW(),
  updated_at timestamp with time zone NOT NULL DEFAULT NOW(),
  CONSTRAINT pet_vaccination_records_source_check
    CHECK (record_source IN ('user', 'imported'))
);

CREATE INDEX IF NOT EXISTS pet_vaccination_records_pet_administered_idx
  ON pet_vaccination_records (pet_id, administered_on DESC);
