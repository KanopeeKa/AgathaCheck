-- AW-4: per-pet carer assignments on planned_absence_pets (D-AWAY-003/004)

ALTER TABLE planned_absence_pets
  ADD COLUMN IF NOT EXISTS carer_kind TEXT,
  ADD COLUMN IF NOT EXISTS carer_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS carer_name TEXT,
  ADD COLUMN IF NOT EXISTS carer_note TEXT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'planned_absence_pets_carer_kind_check'
  ) THEN
    ALTER TABLE planned_absence_pets
      ADD CONSTRAINT planned_absence_pets_carer_kind_check CHECK (
        carer_kind IS NULL OR carer_kind IN ('shared_user', 'note_only')
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'planned_absence_pets_carer_fields_check'
  ) THEN
    ALTER TABLE planned_absence_pets
      ADD CONSTRAINT planned_absence_pets_carer_fields_check CHECK (
        (
          carer_kind IS NULL
          AND carer_user_id IS NULL
          AND carer_name IS NULL
          AND carer_note IS NULL
        )
        OR (
          carer_kind = 'shared_user'
          AND carer_name IS NULL
          AND carer_note IS NULL
        )
        OR (
          carer_kind = 'note_only'
          AND carer_user_id IS NULL
          AND carer_name IS NOT NULL
        )
      );
  END IF;
END $$;
