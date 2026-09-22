-- Phase H: CIM templates use care_family + taxonomy; drop legacy suggested type.
ALTER TABLE care_recommendations
  DROP COLUMN IF EXISTS suggested_health_entry_type;
