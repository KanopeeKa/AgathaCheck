ALTER TABLE planned_absences
  DROP COLUMN IF EXISTS last_handover_downloaded_at,
  DROP COLUMN IF EXISTS handover_note;
