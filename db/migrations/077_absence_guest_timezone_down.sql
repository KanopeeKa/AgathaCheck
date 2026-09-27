DROP TABLE IF EXISTS planned_absence_guest_grants;
DROP TABLE IF EXISTS planned_absence_carer_invite_pets;
DROP TABLE IF EXISTS planned_absence_carer_invites;
ALTER TABLE planned_absences DROP COLUMN IF EXISTS timezone;
ALTER TABLE users DROP COLUMN IF EXISTS timezone;
