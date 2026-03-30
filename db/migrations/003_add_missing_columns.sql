-- Add missing columns to health_entries
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS name VARCHAR(255) DEFAULT '';
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS dosage VARCHAR(255) DEFAULT '';
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS frequency VARCHAR(50) DEFAULT 'once';
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS frequency_days INTEGER;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS frequency_interval INTEGER DEFAULT 1;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS next_due_date TIMESTAMPTZ;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS health_issue_id UUID;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS remind_days_before INTEGER DEFAULT 1;
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';
ALTER TABLE health_entries ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Add missing columns to notifications
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS pet_id UUID;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS pet_name VARCHAR(255);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS health_entry_id UUID;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS organization_id UUID;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS title VARCHAR(255) DEFAULT '';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'general';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;

-- Add missing columns to organizations
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS type VARCHAR(50) DEFAULT 'professional';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS website VARCHAR(255);
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS bio TEXT DEFAULT '';
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT '';

-- Add missing columns to health_issues
ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS name VARCHAR(255) DEFAULT '';
ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE health_issues ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'active';

-- Add missing columns to health_history
ALTER TABLE health_history ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_health_entries_user_id ON health_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_health_entries_pet_id ON health_entries(pet_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name);
CREATE INDEX IF NOT EXISTS idx_org_users_user_id ON organization_users(user_id);
