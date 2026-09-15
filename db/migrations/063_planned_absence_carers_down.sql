ALTER TABLE planned_absence_pets
  DROP CONSTRAINT IF EXISTS planned_absence_pets_carer_fields_check;

ALTER TABLE planned_absence_pets
  DROP CONSTRAINT IF EXISTS planned_absence_pets_carer_kind_check;

ALTER TABLE planned_absence_pets
  DROP COLUMN IF EXISTS carer_note,
  DROP COLUMN IF EXISTS carer_name,
  DROP COLUMN IF EXISTS carer_user_id,
  DROP COLUMN IF EXISTS carer_kind;
