-- Care semantics for health entries (Phase A Care Foundation)
ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS care_family character varying(50),
  ADD COLUMN IF NOT EXISTS care_source character varying(50) DEFAULT 'guardian_defined';

-- Conservative backfill: only map when type is unambiguous
UPDATE health_entries
SET care_family = 'medication'
WHERE care_family IS NULL AND type = 'medication';

UPDATE health_entries
SET care_family = 'wellness_review'
WHERE care_family IS NULL AND type = 'vet_visit';

UPDATE health_entries
SET care_family = 'other'
WHERE care_family IS NULL AND type IN ('preventive', 'other', 'family_event', 'procedure');

UPDATE health_entries
SET care_source = 'guardian_defined'
WHERE care_source IS NULL;
