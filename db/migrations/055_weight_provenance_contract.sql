-- D0: weight provenance contract (nullable / defaulted — capture UI lands in D3)

ALTER TABLE weight_entries
  ADD COLUMN IF NOT EXISTS measurement_source character varying(50) NOT NULL DEFAULT 'guardian';

ALTER TABLE weight_entries
  DROP CONSTRAINT IF EXISTS weight_entries_measurement_source_check;

ALTER TABLE weight_entries
  ADD CONSTRAINT weight_entries_measurement_source_check
  CHECK (measurement_source IN ('guardian', 'clinic', 'device', 'imported'));

UPDATE weight_entries
SET measurement_source = 'guardian'
WHERE measurement_source IS NULL;

ALTER TABLE pets
  ADD COLUMN IF NOT EXISTS weight_reference_value double precision,
  ADD COLUMN IF NOT EXISTS weight_reference_authority character varying(50),
  ADD COLUMN IF NOT EXISTS weight_management_context character varying(50) NOT NULL DEFAULT 'none';

ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_weight_reference_authority_check;

ALTER TABLE pets
  ADD CONSTRAINT pets_weight_reference_authority_check
  CHECK (
    weight_reference_authority IS NULL
    OR weight_reference_authority IN (
      'vet_target',
      'guardian_reference',
      'historical_baseline'
    )
  );

ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_weight_management_context_check;

ALTER TABLE pets
  ADD CONSTRAINT pets_weight_management_context_check
  CHECK (
    weight_management_context IN (
      'none',
      'vet_managed',
      'care_plan',
      'treatment_related'
    )
  );
