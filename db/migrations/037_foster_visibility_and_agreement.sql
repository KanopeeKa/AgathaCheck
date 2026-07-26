-- Phase 4.1: foster self-management visibility, agreement withdrawal, session review flag.
-- Defaults preserve today's behaviour (full visibility to all org members).

ALTER TABLE org_foster_parents
  ADD COLUMN IF NOT EXISTS visible_to TEXT NOT NULL DEFAULT 'both',
  ADD COLUMN IF NOT EXISTS address_visibility TEXT NOT NULL DEFAULT 'full',
  ADD COLUMN IF NOT EXISTS contact_visibility TEXT NOT NULL DEFAULT 'both',
  ADD COLUMN IF NOT EXISTS rules_agreement_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notification_message_channel TEXT NOT NULL DEFAULT 'in_app';

ALTER TABLE org_foster_parents
  DROP CONSTRAINT IF EXISTS org_foster_parents_visible_to_check;

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_visible_to_check
  CHECK (visible_to IN ('other_fosters', 'admins', 'both', 'nobody'));

ALTER TABLE org_foster_parents
  DROP CONSTRAINT IF EXISTS org_foster_parents_address_visibility_check;

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_address_visibility_check
  CHECK (address_visibility IN ('full', 'town', 'hidden'));

ALTER TABLE org_foster_parents
  DROP CONSTRAINT IF EXISTS org_foster_parents_contact_visibility_check;

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_contact_visibility_check
  CHECK (contact_visibility IN ('email', 'phone', 'neither', 'both'));

ALTER TABLE org_foster_parents
  DROP CONSTRAINT IF EXISTS org_foster_parents_notification_message_channel_check;

ALTER TABLE org_foster_parents
  ADD CONSTRAINT org_foster_parents_notification_message_channel_check
  CHECK (notification_message_channel IN ('in_app', 'email', 'both'));

ALTER TABLE foster_placements
  ADD COLUMN IF NOT EXISTS flagged_for_admin_review BOOLEAN NOT NULL DEFAULT false;
