-- Three-date event model: due date, completed on, marked-as-completed audit.
-- Recurrence anchor toggle for health/care entries.

BEGIN;

-- ── health_entries ───────────────────────────────────────────
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS completed_on DATE;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS recurrence_anchor VARCHAR(50) DEFAULT 'from_completion';
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS repeat_end_date DATE;

-- Existing recurring entries keep fixed-schedule behavior.
UPDATE health_entries
SET recurrence_anchor = 'from_due_date'
WHERE frequency IS DISTINCT FROM 'once'
  AND (recurrence_anchor IS NULL OR recurrence_anchor = 'from_completion');

-- One-time entries completed via the legacy 9999 sentinel → explicit completed_on.
UPDATE health_entries
SET completed_on = COALESCE(DATE(completed_at), DATE(start_date), CURRENT_DATE),
    next_due_date = NULL
WHERE frequency = 'once'
  AND next_due_date IS NOT NULL
  AND next_due_date >= TIMESTAMPTZ '9999-12-31 00:00:00+00'
  AND completed_on IS NULL;

-- ── health_history ───────────────────────────────────────────
ALTER TABLE health_history ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE health_history ADD COLUMN IF NOT EXISTS completed_on DATE;
ALTER TABLE health_history ADD COLUMN IF NOT EXISTS marked_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- ── family_events (org foster/placement) ─────────────────────
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS pet_id UUID REFERENCES pets(id) ON DELETE CASCADE;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS assigned_to_user_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS from_date DATE;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS to_date DATE;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE family_events ADD COLUMN IF NOT EXISTS marked_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_family_events_pet_id ON family_events(pet_id);
CREATE INDEX IF NOT EXISTS idx_family_events_org_id ON family_events(organization_id);

CREATE TABLE IF NOT EXISTS family_event_history (
  id UUID PRIMARY KEY,
  family_event_id UUID NOT NULL REFERENCES family_events(id) ON DELETE CASCADE,
  due_date DATE,
  completed_on DATE,
  marked_at TIMESTAMPTZ DEFAULT NOW(),
  marked_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  notes TEXT DEFAULT '',
  status VARCHAR(50) NOT NULL DEFAULT 'completed'
);

CREATE INDEX IF NOT EXISTS idx_family_event_history_event_id ON family_event_history(family_event_id);

COMMIT;
