-- Organisation branding (logo) and primary emergency contact.

ALTER TABLE organizations
  ADD COLUMN IF NOT EXISTS logo_url TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS primary_contact_ref TEXT DEFAULT NULL;
