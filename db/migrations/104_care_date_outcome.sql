-- Care date stored outcome (CARE-STATUS-R-001): extend status enum; backfill in JS hook.

BEGIN;

ALTER TABLE health_occurrences DROP CONSTRAINT IF EXISTS health_occurrences_close_reason_check;
ALTER TABLE health_occurrences DROP CONSTRAINT IF EXISTS health_occurrences_status_check;

COMMIT;
