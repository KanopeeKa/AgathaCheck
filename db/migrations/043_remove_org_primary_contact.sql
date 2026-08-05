-- Remove deprecated organisation primary/emergency contact reference.
ALTER TABLE organizations DROP COLUMN IF EXISTS primary_contact_ref;
