DROP INDEX IF EXISTS idx_pet_contact_rel_one_active_out_of_hours_vet;
DROP INDEX IF EXISTS idx_pet_contact_rel_one_active_primary_vet;

ALTER TABLE pet_contact_relationships
  DROP COLUMN IF EXISTS sort_order;
