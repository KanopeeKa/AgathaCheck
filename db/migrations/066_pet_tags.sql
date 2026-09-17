-- Private per-user pet tags for list organization (Pet Tags v1)

CREATE TABLE IF NOT EXISTS pet_tags (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(64) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pet_tags_user_name_lower
  ON pet_tags (user_id, lower(name));

CREATE TABLE IF NOT EXISTS pet_tag_assignments (
  pet_tag_id UUID NOT NULL REFERENCES pet_tags(id) ON DELETE CASCADE,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (pet_tag_id, pet_id)
);

CREATE INDEX IF NOT EXISTS idx_pet_tag_assignments_pet_id
  ON pet_tag_assignments (pet_id);
