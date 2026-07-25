-- J1 Phase 2: shelter–foster relationship approval state (G0 §5.1, migration appendix §2.2).

ALTER TABLE org_foster_parents
  ADD COLUMN IF NOT EXISTS approval_state VARCHAR(32) NOT NULL DEFAULT 'approved',
  ADD COLUMN IF NOT EXISTS creation_source VARCHAR(32);

UPDATE org_foster_parents
SET creation_source = 'manual_shelter_entry'
WHERE creation_source IS NULL;

ALTER TABLE org_foster_parents
  ALTER COLUMN creation_source SET DEFAULT 'manual_shelter_entry';

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_approval_state_check
    CHECK (approval_state IN ('under_review', 'approved', 'declined', 'archived'));

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_creation_source_check
    CHECK (creation_source IN ('invite', 'manual_shelter_entry', 'member'));
