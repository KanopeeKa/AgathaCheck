-- People product phase 0: contact directories and relationships (D11).
-- Personal directories only; household_id wiring ships in phase 3.

CREATE TABLE IF NOT EXISTS people_directories (
  id              UUID PRIMARY KEY,
  owner_user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT people_directories_owner_user_unique UNIQUE (owner_user_id)
);

CREATE TABLE IF NOT EXISTS people_contacts (
  id                    UUID PRIMARY KEY,
  directory_id          UUID NOT NULL REFERENCES people_directories(id) ON DELETE CASCADE,
  kind                  TEXT NOT NULL CHECK (kind IN ('person', 'organisation')),
  name                  TEXT NOT NULL,
  phone                 TEXT,
  email                 TEXT,
  address               TEXT,
  website               TEXT,
  works_at_contact_id   UUID REFERENCES people_contacts(id) ON DELETE SET NULL,
  linked_user_id        UUID REFERENCES users(id) ON DELETE SET NULL,
  inactive_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS people_contact_roles (
  contact_id  UUID NOT NULL REFERENCES people_contacts(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (
    role IN (
      'sitter', 'walker', 'vet', 'vet_nurse', 'groomer', 'trainer',
      'behaviourist', 'boarding', 'emergency_contact', 'other'
    )
  ),
  PRIMARY KEY (contact_id, role)
);

CREATE TABLE IF NOT EXISTS people_contact_private_notes (
  contact_id   UUID NOT NULL REFERENCES people_contacts(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note         TEXT NOT NULL DEFAULT '',
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (contact_id, user_id)
);

CREATE TABLE IF NOT EXISTS pet_contact_relationships (
  id                 UUID PRIMARY KEY,
  pet_id             UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  contact_id         UUID NOT NULL REFERENCES people_contacts(id) ON DELETE RESTRICT,
  relationship_kind  TEXT NOT NULL CHECK (
    relationship_kind IN (
      'primary_vet', 'out_of_hours_vet', 'emergency_contact', 'care_provider', 'other'
    )
  ),
  is_primary         BOOLEAN NOT NULL DEFAULT false,
  active             BOOLEAN NOT NULL DEFAULT true,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_people_contacts_directory_id
  ON people_contacts (directory_id);

CREATE INDEX IF NOT EXISTS idx_pet_contact_relationships_pet_id
  ON pet_contact_relationships (pet_id);

CREATE INDEX IF NOT EXISTS idx_pet_contact_relationships_contact_id
  ON pet_contact_relationships (contact_id);
