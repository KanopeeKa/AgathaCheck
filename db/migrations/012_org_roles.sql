-- Organisation role model: super_admin, admin, foster (+ pending_* variants).
-- Existing super_user and member rows become super_admin (test env; preserves control).

BEGIN;

UPDATE organization_users SET role = 'super_admin' WHERE role IN ('super_user', 'member');
UPDATE organization_users SET role = 'pending_super_admin' WHERE role IN ('pending_super_user', 'pending_member');

COMMIT;
