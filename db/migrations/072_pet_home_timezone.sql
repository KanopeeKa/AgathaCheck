-- D-CIE-023: pet home IANA timezone for care "today" and overdue (Phase A1).

ALTER TABLE pets
  ADD COLUMN IF NOT EXISTS home_timezone TEXT NOT NULL DEFAULT 'UTC';
