-- Foster adoption lifecycle (Inc 6): waiting_adoption_confirmation → adopted.

ALTER TABLE foster_placements
  ADD COLUMN IF NOT EXISTS adoption_conditions TEXT DEFAULT '';

DROP INDEX IF EXISTS idx_foster_placements_one_active_pet;
CREATE UNIQUE INDEX idx_foster_placements_one_active_pet
  ON foster_placements(pet_id)
  WHERE status IN (
    'pending',
    'in_progress',
    'waiting_adoption_confirmation',
    'pending_adoption_conditions'
  );
