-- Phase 3.1: organisation discoverability + legal identifier fields (program-contract §5).

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS town VARCHAR(120),
  ADD COLUMN IF NOT EXISTS administrative_area VARCHAR(120),
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS is_discoverable BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS legal_identifier_1 VARCHAR(64),
  ADD COLUMN IF NOT EXISTS legal_identifier_2 VARCHAR(64),
  ADD COLUMN IF NOT EXISTS legal_identifier_3 VARCHAR(64),
  ADD COLUMN IF NOT EXISTS public_profile_metadata JSONB NOT NULL DEFAULT '{}'::jsonb;
