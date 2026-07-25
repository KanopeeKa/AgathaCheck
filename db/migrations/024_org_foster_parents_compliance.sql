-- J1 Phase 4: outreach opt-out and retention category on shelter–foster relationships.

ALTER TABLE org_foster_parents
  ADD COLUMN IF NOT EXISTS opt_out_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS retention_category TEXT NOT NULL DEFAULT 'shelter_foster_relationship';

ALTER TABLE org_foster_parents
  DROP CONSTRAINT IF EXISTS org_foster_parents_retention_category_check;

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_retention_category_check
  CHECK (retention_category IN (
    'shelter_foster_relationship',
    'declined_archived',
    'manual_contact'
  ));

UPDATE org_foster_parents
SET retention_category = 'declined_archived'
WHERE approval_state IN ('declined', 'archived')
  AND retention_category = 'shelter_foster_relationship';

UPDATE org_foster_parents
SET retention_category = 'manual_contact'
WHERE creation_source = 'manual_shelter_entry'
  AND user_id IS NULL
  AND retention_category = 'shelter_foster_relationship';
