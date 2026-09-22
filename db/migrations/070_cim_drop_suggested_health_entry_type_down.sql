ALTER TABLE care_recommendations
  ADD COLUMN IF NOT EXISTS suggested_health_entry_type VARCHAR(30) NOT NULL DEFAULT 'other';
