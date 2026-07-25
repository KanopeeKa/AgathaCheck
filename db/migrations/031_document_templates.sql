-- G1 Phase 1–2: document template storage and checklist hooks (G0 §5.7).

CREATE TABLE IF NOT EXISTS document_templates (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  template_key VARCHAR(128) NOT NULL,
  template_type VARCHAR(64) NOT NULL,
  label VARCHAR(255) NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  sort_order INT NOT NULL DEFAULT 0,
  is_required BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT document_templates_type_check
    CHECK (template_type IN ('session_checklist', 'adoption_milestone')),
  CONSTRAINT document_templates_org_key_unique
    UNIQUE (organization_id, template_key)
);

CREATE INDEX IF NOT EXISTS idx_document_templates_org_type
  ON document_templates(organization_id, template_type);

ALTER TABLE foster_placements
  ADD COLUMN IF NOT EXISTS session_checklist_items JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE adoption_journeys
  ADD COLUMN IF NOT EXISTS milestone_items JSONB NOT NULL DEFAULT '{}'::jsonb;
