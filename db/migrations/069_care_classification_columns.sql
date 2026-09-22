-- Care classification axes (care-classification-taxonomy Phase B)
ALTER TABLE health_entries
  ADD COLUMN IF NOT EXISTS care_setting VARCHAR(20),
  ADD COLUMN IF NOT EXISTS care_planning VARCHAR(20),
  ADD COLUMN IF NOT EXISTS care_importance VARCHAR(20),
  ADD COLUMN IF NOT EXISTS importance_overridden BOOLEAN DEFAULT false;

-- care_setting from family defaults (§4.3 spec); null family → other
UPDATE health_entries
SET care_setting = CASE care_family
  WHEN 'medication' THEN 'home'
  WHEN 'vaccination' THEN 'vet'
  WHEN 'parasite_prevention' THEN 'home'
  WHEN 'wellness_review' THEN 'vet'
  WHEN 'dental' THEN 'vet'
  WHEN 'weight_monitoring' THEN 'home'
  WHEN 'grooming' THEN 'other'
  WHEN 'nail_care' THEN 'other'
  WHEN 'other' THEN 'other'
  ELSE 'other'
END
WHERE care_setting IS NULL;

UPDATE health_entries
SET care_importance = CASE care_family
  WHEN 'medication' THEN 'essential'
  WHEN 'vaccination' THEN 'essential'
  WHEN 'parasite_prevention' THEN 'essential'
  WHEN 'wellness_review' THEN 'recommended'
  WHEN 'dental' THEN 'recommended'
  WHEN 'weight_monitoring' THEN 'recommended'
  WHEN 'grooming' THEN 'optional'
  WHEN 'nail_care' THEN 'optional'
  WHEN 'other' THEN 'optional'
  ELSE 'optional'
END
WHERE care_importance IS NULL;

-- Default all legacy rows to planned; refine confident unplanned below.
UPDATE health_entries
SET care_planning = 'planned'
WHERE care_planning IS NULL;

UPDATE health_entries he
SET care_planning = 'unplanned'
WHERE he.frequency = 'once'
  AND he.completed_on IS NOT NULL
  AND he.next_due_date IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM health_occurrences ho WHERE ho.health_entry_id = he.id
  )
  AND NOT EXISTS (
    SELECT 1 FROM health_history hh
    WHERE hh.health_entry_id = he.id AND hh.due_date IS NOT NULL
  )
  AND he.created_at::date = he.completed_on;

UPDATE health_entries
SET importance_overridden = false
WHERE importance_overridden IS NULL;

ALTER TABLE health_entries
  ALTER COLUMN care_setting SET DEFAULT 'home',
  ALTER COLUMN care_planning SET DEFAULT 'planned',
  ALTER COLUMN importance_overridden SET DEFAULT false;

ALTER TABLE health_entries
  ALTER COLUMN care_setting SET NOT NULL,
  ALTER COLUMN care_planning SET NOT NULL,
  ALTER COLUMN care_importance SET NOT NULL,
  ALTER COLUMN importance_overridden SET NOT NULL;
