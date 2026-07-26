ALTER TABLE foster_placements DROP COLUMN IF EXISTS flagged_for_admin_review;

ALTER TABLE org_foster_parents DROP CONSTRAINT IF EXISTS org_foster_parents_notification_message_channel_check;
ALTER TABLE org_foster_parents DROP CONSTRAINT IF EXISTS org_foster_parents_contact_visibility_check;
ALTER TABLE org_foster_parents DROP CONSTRAINT IF EXISTS org_foster_parents_address_visibility_check;
ALTER TABLE org_foster_parents DROP CONSTRAINT IF EXISTS org_foster_parents_visible_to_check;

ALTER TABLE org_foster_parents
  DROP COLUMN IF EXISTS notification_message_channel,
  DROP COLUMN IF EXISTS rules_agreement_at,
  DROP COLUMN IF EXISTS contact_visibility,
  DROP COLUMN IF EXISTS address_visibility,
  DROP COLUMN IF EXISTS visible_to;
