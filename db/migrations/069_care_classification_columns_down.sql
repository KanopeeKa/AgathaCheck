ALTER TABLE health_entries
  DROP COLUMN IF EXISTS importance_overridden,
  DROP COLUMN IF EXISTS care_importance,
  DROP COLUMN IF EXISTS care_planning,
  DROP COLUMN IF EXISTS care_setting;
