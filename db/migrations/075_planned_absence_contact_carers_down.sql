DROP INDEX IF EXISTS idx_planned_absence_pets_contact_id;

ALTER TABLE planned_absence_pets
  DROP COLUMN IF EXISTS contact_id;
