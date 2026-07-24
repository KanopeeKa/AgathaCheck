-- Nullable organization_id: null = personal vet, set = org-scoped vet (navigation v2).
ALTER TABLE vets ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_vets_organization_id ON vets(organization_id);
