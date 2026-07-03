DROP INDEX IF EXISTS idx_foster_placements_one_active_pet;
CREATE UNIQUE INDEX idx_foster_placements_one_active_pet
  ON foster_placements(pet_id)
  WHERE status IN ('pending', 'in_progress');

ALTER TABLE foster_placements DROP COLUMN IF EXISTS adoption_conditions;
