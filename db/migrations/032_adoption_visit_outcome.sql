-- Wave C: single visit_outcome field (replaces outcome + validation_status).

ALTER TABLE adoption_visits DROP CONSTRAINT IF EXISTS adoption_visits_outcome_check;
ALTER TABLE adoption_visits DROP CONSTRAINT IF EXISTS adoption_visits_validation_status_check;

ALTER TABLE adoption_visits RENAME COLUMN outcome TO visit_outcome;

ALTER TABLE adoption_visits DROP COLUMN IF EXISTS validation_status;
ALTER TABLE adoption_visits DROP COLUMN IF EXISTS validated_at;
ALTER TABLE adoption_visits DROP COLUMN IF EXISTS validated_by;

ALTER TABLE adoption_visits ADD CONSTRAINT adoption_visits_visit_outcome_check
  CHECK (visit_outcome IS NULL OR visit_outcome IN ('positive', 'negative', 'no_show'));
