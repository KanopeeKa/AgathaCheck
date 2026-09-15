-- AW-9: handover document metadata on planned_absences (D-AWAY-008, D-AWAY-009)

ALTER TABLE planned_absences
  ADD COLUMN IF NOT EXISTS handover_note TEXT,
  ADD COLUMN IF NOT EXISTS last_handover_downloaded_at TIMESTAMPTZ;
