-- Migrate legacy family_events foster/placement rows into foster_placements (Inc 7).
-- Idempotent: skips rows that already have a matching foster_placements record.

INSERT INTO foster_placements (
  id,
  organization_id,
  pet_id,
  foster_user_id,
  status,
  start_date,
  end_date,
  notes,
  created_by,
  created_at,
  updated_at
)
SELECT
  gen_random_uuid(),
  fe.organization_id,
  fe.pet_id,
  fe.assigned_to_user_id,
  'not_in_foster',
  fe.from_date,
  COALESCE(fe.to_date, fe.from_date),
  TRIM(COALESCE(fe.notes, '') || ' [migrated from family_events]'),
  fe.created_by,
  fe.created_at,
  COALESCE(fe.updated_at, fe.created_at)
FROM family_events fe
WHERE fe.pet_id IS NOT NULL
  AND fe.organization_id IS NOT NULL
  AND fe.assigned_to_user_id IS NOT NULL
  AND fe.event_type IN ('placement', 'foster')
  AND NOT EXISTS (
    SELECT 1
    FROM foster_placements fp
    WHERE fp.pet_id = fe.pet_id
      AND fp.foster_user_id = fe.assigned_to_user_id
      AND fp.start_date IS NOT DISTINCT FROM fe.from_date
  );
