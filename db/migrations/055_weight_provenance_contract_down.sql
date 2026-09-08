ALTER TABLE pets
  DROP CONSTRAINT IF EXISTS pets_weight_management_context_check,
  DROP CONSTRAINT IF EXISTS pets_weight_reference_authority_check,
  DROP COLUMN IF EXISTS weight_management_context,
  DROP COLUMN IF EXISTS weight_reference_authority,
  DROP COLUMN IF EXISTS weight_reference_value;

ALTER TABLE weight_entries
  DROP CONSTRAINT IF EXISTS weight_entries_measurement_source_check,
  DROP COLUMN IF EXISTS measurement_source;
