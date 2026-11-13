-- Reverse support intake tables (dev only).

BEGIN;

DROP TABLE IF EXISTS support_outbox;
DROP TABLE IF EXISTS support_attachments;
DROP TABLE IF EXISTS support_tickets;

ALTER TABLE users DROP COLUMN IF EXISTS is_support_staff;

COMMIT;
