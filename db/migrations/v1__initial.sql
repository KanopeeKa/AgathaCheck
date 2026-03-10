-- 001_initial_schema.sql
-- Agatha Track — full database schema (up migration)
-- Compatible with PostgreSQL 14+

BEGIN;

-- ── Users ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL DEFAULT '',
  first_name VARCHAR(100) DEFAULT '',
  last_name VARCHAR(100) DEFAULT '',
  category VARCHAR(50) DEFAULT 'pet_guardian',
  bio TEXT DEFAULT '',
  photo_url TEXT DEFAULT '',
  locale VARCHAR(10) DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Authentication tokens ────────────────────────────────────

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Organizations ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS organizations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'professional',
  email VARCHAR(255) DEFAULT '',
  phone VARCHAR(100) DEFAULT '',
  address TEXT DEFAULT '',
  website VARCHAR(255) DEFAULT '',
  bio TEXT DEFAULT '',
  photo_url TEXT DEFAULT '',
  created_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organization_users (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'member',
  invited_by INTEGER REFERENCES users(id),
  invite_code VARCHAR(20) UNIQUE,
  invite_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

-- ── Veterinarians ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS vets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  website TEXT,
  address TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vets_user_id ON vets(user_id);

-- ── Pets ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS pets (
  id VARCHAR(255) PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(100) NOT NULL,
  breed VARCHAR(255) DEFAULT '',
  age DOUBLE PRECISION,
  date_of_birth DATE,
  weight DOUBLE PRECISION,
  gender VARCHAR(50),
  bio TEXT DEFAULT '',
  insurance TEXT DEFAULT '',
  neutered_date DATE,
  neuter_dismissed BOOLEAN DEFAULT FALSE,
  chip_id VARCHAR(255) DEFAULT '',
  chip_dismissed BOOLEAN DEFAULT FALSE,
  photo_path TEXT,
  vet_id INTEGER,
  color_value BIGINT,
  passed_away BOOLEAN DEFAULT FALSE,
  organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pets_user_id ON pets(user_id);
CREATE INDEX IF NOT EXISTS idx_pets_organization_id ON pets(organization_id);

-- ── Sharing ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS shared_pets (
  id SERIAL PRIMARY KEY,
  share_code VARCHAR(12) UNIQUE NOT NULL,
  pet_data JSONB NOT NULL,
  pet_id VARCHAR(255) NOT NULL,
  user_id INTEGER DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pet_access (
  id SERIAL PRIMARY KEY,
  pet_id VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'shared',
  invited_by INTEGER REFERENCES users(id),
  share_code VARCHAR(12) UNIQUE,
  target_organization_id INTEGER REFERENCES organizations(id),
  hidden BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pet_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pet_access_user_id ON pet_access(user_id);
CREATE INDEX IF NOT EXISTS idx_pet_access_pet_id ON pet_access(pet_id);

-- ── Health tracking ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS health_issues (
  id SERIAL PRIMARY KEY,
  pet_id VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_issues_pet_id ON health_issues(pet_id);

CREATE TABLE IF NOT EXISTS health_entries (
  id UUID PRIMARY KEY,
  pet_id TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type = ANY (ARRAY['medication','preventive','vet_visit','procedure'])),
  dosage TEXT NOT NULL DEFAULT '',
  frequency TEXT NOT NULL CHECK (frequency = ANY (ARRAY['once','daily','weekly','monthly','yearly','custom'])),
  frequency_days INTEGER,
  frequency_interval INTEGER DEFAULT 1,
  start_date DATE NOT NULL,
  next_due_date TIMESTAMPTZ NOT NULL,
  repeat_end_date DATE,
  remind_days_before INTEGER NOT NULL DEFAULT 1,
  health_issue_id INTEGER REFERENCES health_issues(id) ON DELETE SET NULL,
  notes TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_entries_pet_id ON health_entries(pet_id);

CREATE TABLE IF NOT EXISTS health_history (
  id UUID PRIMARY KEY,
  entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notes TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_health_history_entry_id ON health_history(entry_id);

CREATE TABLE IF NOT EXISTS health_event_photos (
  id SERIAL PRIMARY KEY,
  event_id VARCHAR(255) NOT NULL,
  photo_path TEXT NOT NULL,
  caption TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_event_photos_event_id ON health_event_photos(event_id);

CREATE TABLE IF NOT EXISTS health_issue_events (
  health_issue_id INT NOT NULL REFERENCES health_issues(id) ON DELETE CASCADE,
  health_entry_id UUID NOT NULL,
  PRIMARY KEY (health_issue_id, health_entry_id)
);

-- ── Weight tracking ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS weight_entries (
  id SERIAL PRIMARY KEY,
  pet_id VARCHAR(255) NOT NULL,
  date DATE NOT NULL,
  weight DOUBLE PRECISION NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weight_entries_pet_id ON weight_entries(pet_id);

-- ── Notifications ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id VARCHAR(255),
  health_entry_id VARCHAR(255),
  organization_id INTEGER REFERENCES organizations(id),
  title VARCHAR(500) NOT NULL,
  message TEXT NOT NULL DEFAULT '',
  type VARCHAR(50) NOT NULL DEFAULT 'reminder',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_pet_id ON notifications(pet_id);

CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email_reminders_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  reminder_days_before INTEGER NOT NULL DEFAULT 1,
  notify_completed BOOLEAN NOT NULL DEFAULT TRUE,
  muted_pet_ids TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Archived pets ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS archived_pets (
  id SERIAL PRIMARY KEY,
  organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  pet_id VARCHAR(255) NOT NULL,
  pet_name VARCHAR(255) NOT NULL DEFAULT '',
  species VARCHAR(100) NOT NULL DEFAULT '',
  pdf_data TEXT DEFAULT '',
  transfer_type VARCHAR(50) NOT NULL DEFAULT 'other',
  transferred_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  transferred_to_org_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
  notes TEXT DEFAULT '',
  archived_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Family events ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS family_events (
  id SERIAL PRIMARY KEY,
  pet_id VARCHAR(255) NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  assigned_to_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  from_date DATE NOT NULL,
  to_date DATE,
  notes TEXT DEFAULT '',
  created_by INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_family_events_pet_id ON family_events(pet_id);
CREATE INDEX IF NOT EXISTS idx_family_events_org_id ON family_events(organization_id);

-- ── Migration tracking ──────────────────────────────────────

CREATE TABLE IF NOT EXISTS _migrations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO _migrations (name) VALUES ('001_initial_schema')
  ON CONFLICT (name) DO NOTHING;

COMMIT;
