-- AW-11: per-pet handover note on planned_absence_pets (D-AWAY-014a)
-- Independent of carer_kind — usable for shared_user and note_only carers alike.

ALTER TABLE planned_absence_pets
  ADD COLUMN IF NOT EXISTS pet_note TEXT;
