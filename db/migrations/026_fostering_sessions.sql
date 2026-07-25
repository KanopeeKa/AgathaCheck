-- J3 Phase 1: evolve foster_placements into fostering sessions (migration appendix §2.1, §3).

ALTER TABLE foster_placements
  ADD COLUMN IF NOT EXISTS shelter_foster_relationship_id UUID REFERENCES org_foster_parents(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS session_type TEXT NOT NULL DEFAULT 'standard_foster',
  ADD COLUMN IF NOT EXISTS foster_request_response_id UUID,
  ADD COLUMN IF NOT EXISTS shelter_start_confirmed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS foster_start_confirmed_at TIMESTAMPTZ;

ALTER TABLE foster_placements
  ADD CONSTRAINT foster_placements_session_type_check
    CHECK (session_type IN ('standard_foster', 'foster_in_view_to_adopt'));

UPDATE foster_placements
SET shelter_foster_relationship_id = org_foster_parent_id
WHERE shelter_foster_relationship_id IS NULL
  AND org_foster_parent_id IS NOT NULL;

UPDATE foster_placements
SET foster_start_confirmed_at = responded_at
WHERE status = 'in_progress'
  AND foster_start_confirmed_at IS NULL
  AND responded_at IS NOT NULL;

-- Status migration (appendix §3.1)
UPDATE foster_placements SET status = 'pending_acceptance' WHERE status = 'pending';
UPDATE foster_placements SET status = 'active' WHERE status = 'in_progress';
UPDATE foster_placements SET status = 'adoption_in_progress' WHERE status = 'waiting_adoption_confirmation';
UPDATE foster_placements SET status = 'adoption_in_progress' WHERE status = 'pending_adoption_conditions';
UPDATE foster_placements SET status = 'converted_to_adoption' WHERE status = 'adopted';
UPDATE foster_placements SET status = 'cancelled' WHERE status = 'not_in_foster';

ALTER TABLE foster_placements
  ALTER COLUMN foster_user_id DROP NOT NULL;

DROP INDEX IF EXISTS idx_foster_placements_one_active_pet;

CREATE UNIQUE INDEX idx_foster_placements_one_open_session_per_pet
  ON foster_placements (pet_id)
  WHERE status IN (
    'pending_acceptance',
    'preparation',
    'ready_to_start',
    'active',
    'end_pending_confirmation',
    'adoption_in_progress',
    'pending',
    'in_progress',
    'waiting_adoption_confirmation',
    'pending_adoption_conditions'
  );
