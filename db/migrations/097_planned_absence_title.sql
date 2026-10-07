-- Planned absence optional display title (D-CC-ABS-001)

ALTER TABLE planned_absences
  ADD COLUMN IF NOT EXISTS title VARCHAR(60);
