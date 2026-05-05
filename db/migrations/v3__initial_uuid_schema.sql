-- Agatha Track — full database schema (UUID version, canonical).
--
-- This file is the single source of truth for a fresh install: running
-- it on an empty database produces the exact schema the application code
-- expects, with all migrations 001–007 already inlined.
--
-- Existing databases should NOT replay this file; they should run only
-- the incremental NNN_*.sql migrations they haven't applied yet (tracked
-- in the _migrations table by `bin/migrate.dart`).
--
-- Compatible with PostgreSQL 13+ (no uuid-ossp required; uses gen_random_uuid()).

BEGIN;

-- ── Users ────────────────────────────────────────────────────
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  -- name field deliberately removed; first_name / last_name only
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
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(255) UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE password_reset_tokens (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Vets ─────────────────────────────────────────────────────
CREATE TABLE vets (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  clinic VARCHAR(255),
  phone VARCHAR(50),
  email VARCHAR(255),
  website VARCHAR DEFAULT '',
  address TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Organizations ────────────────────────────────────────────
CREATE TABLE organizations (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) DEFAULT 'professional',
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  website VARCHAR(255),
  bio TEXT DEFAULT '',
  photo_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE organization_users (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(organization_id, user_id)
);

-- ── Pets ─────────────────────────────────────────────────────
CREATE TABLE pets (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  species VARCHAR(100) NOT NULL,
  breed VARCHAR(100) DEFAULT '',
  age DOUBLE PRECISION,
  date_of_birth DATE,
  weight DOUBLE PRECISION,
  gender VARCHAR(20),
  bio TEXT DEFAULT '',
  insurance TEXT DEFAULT '',
  neutered_date DATE,
  neuter_dismissed BOOLEAN DEFAULT FALSE,
  chip_id TEXT DEFAULT '',
  chip_dismissed BOOLEAN DEFAULT FALSE,
  photo_path TEXT,
  vet_id UUID REFERENCES vets(id) ON DELETE SET NULL,
  color_index BIGINT,
  identification TEXT,
  passed_away BOOLEAN DEFAULT FALSE,
  organization_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Pet Access (sharing) ─────────────────────────────────────
CREATE TABLE pet_access (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'shared',
  hidden BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Shared Pets (legacy companion to pet_access; reserved) ───
CREATE TABLE shared_pets (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(50) DEFAULT 'shared',
  invited_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(pet_id, user_id)
);

-- ── Health Tracking ──────────────────────────────────────────
CREATE TABLE health_entries (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  name VARCHAR(255) DEFAULT '',
  dosage VARCHAR(255) DEFAULT '',
  frequency VARCHAR(50) DEFAULT 'once',
  frequency_days INTEGER,
  frequency_interval INTEGER DEFAULT 1,
  start_date DATE,
  next_due_date TIMESTAMPTZ,
  notes TEXT DEFAULT '',
  health_issue_id UUID,
  remind_days_before INTEGER DEFAULT 1,
  status VARCHAR(50) DEFAULT 'active',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE health_issues (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  issue_type VARCHAR(50) NOT NULL,
  name VARCHAR(255) DEFAULT '',
  notes TEXT DEFAULT '',
  start_date DATE,
  end_date DATE,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE health_event_photos (
  id UUID PRIMARY KEY,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE health_history (
  id UUID PRIMARY KEY,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  status VARCHAR(50) NOT NULL,
  notes TEXT DEFAULT '',
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE health_issue_events (
  id UUID PRIMARY KEY,
  health_issue_id UUID NOT NULL REFERENCES health_issues(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Weight Tracking ──────────────────────────────────────────
CREATE TABLE weight_entries (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  weight DOUBLE PRECISION NOT NULL,
  unit VARCHAR(10) DEFAULT 'kg',
  date DATE,
  notes TEXT DEFAULT '',
  measured_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Notifications ───────────────────────────────────────────
CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pet_id UUID,
  pet_name VARCHAR(255),
  health_entry_id UUID,
  organization_id UUID,
  title VARCHAR(255) DEFAULT '',
  type VARCHAR(50) DEFAULT 'general',
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE notification_preferences (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  preference VARCHAR(50) NOT NULL,
  value VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Family Events (reserved; routes are stubs today) ────────
CREATE TABLE family_events (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Archived Pets (transfer record) ─────────────────────────
CREATE TABLE archived_pets (
  id UUID PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  pet_id UUID,
  pet_name VARCHAR(255) DEFAULT '',
  species VARCHAR(100) DEFAULT '',
  pdf_data TEXT DEFAULT '',
  transfer_type VARCHAR(50) DEFAULT 'other',
  transferred_to_user_id UUID,
  transferred_to_org_id UUID,
  notes TEXT DEFAULT '',
  archived_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Migrations tracking ─────────────────────────────────────
CREATE TABLE _migrations (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Performance indexes ─────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_health_entries_user_id ON health_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_health_entries_pet_id ON health_entries(pet_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
CREATE INDEX IF NOT EXISTS idx_org_users_user_id ON organization_users(user_id);
CREATE INDEX IF NOT EXISTS idx_archived_pets_organization_id ON archived_pets(organization_id);

COMMIT;
