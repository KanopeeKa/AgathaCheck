-- People relationship slots: sort_order + at-most-one active primary/out-of-hours vet per pet.

ALTER TABLE pet_contact_relationships
  ADD COLUMN IF NOT EXISTS sort_order SMALLINT NOT NULL DEFAULT 0;

DO $$
DECLARE
  deactivated_count integer := 0;
BEGIN
  WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (
             PARTITION BY pet_id, relationship_kind
             ORDER BY updated_at DESC, id DESC
           ) AS rn
    FROM pet_contact_relationships
    WHERE active = true
      AND relationship_kind IN ('primary_vet', 'out_of_hours_vet')
  ),
  deactivated AS (
    UPDATE pet_contact_relationships pcr
    SET active = false, updated_at = NOW()
    FROM ranked r
    WHERE pcr.id = r.id AND r.rn > 1
    RETURNING pcr.id
  )
  SELECT COUNT(*)::integer INTO deactivated_count FROM deactivated;

  RAISE NOTICE 'people_relationship_slots: deactivated % duplicate active slot row(s)', deactivated_count;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_contact_rel_one_active_primary_vet
  ON pet_contact_relationships (pet_id)
  WHERE active AND relationship_kind = 'primary_vet';

CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_contact_rel_one_active_out_of_hours_vet
  ON pet_contact_relationships (pet_id)
  WHERE active AND relationship_kind = 'out_of_hours_vet';
