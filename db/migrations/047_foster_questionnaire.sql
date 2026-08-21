-- J1 Phase 5: foster candidate questionnaire engine (form v1.3).

CREATE TABLE IF NOT EXISTS foster_questionnaire_org_settings (
  organization_id UUID PRIMARY KEY REFERENCES organizations(id) ON DELETE CASCADE,
  minimum_age INT NOT NULL DEFAULT 21,
  light_touch_review BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_questionnaire_org_settings_minimum_age_check
    CHECK (minimum_age >= 16 AND minimum_age <= 99)
);

CREATE TABLE IF NOT EXISTS foster_questionnaire_templates (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  version VARCHAR(16) NOT NULL,
  definition JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_questionnaire_templates_org_version_unique
    UNIQUE (organization_id, version)
);

CREATE INDEX IF NOT EXISTS idx_foster_questionnaire_templates_org
  ON foster_questionnaire_templates(organization_id);

CREATE TABLE IF NOT EXISTS foster_questionnaire_submissions (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  org_foster_parent_id UUID NOT NULL REFERENCES org_foster_parents(id) ON DELETE CASCADE,
  template_version VARCHAR(16) NOT NULL,
  result VARCHAR(32) NOT NULL,
  q02_b_mandatory_followup BOOLEAN NOT NULL DEFAULT false,
  general_note TEXT NOT NULL DEFAULT '',
  candidate_acknowledged BOOLEAN NOT NULL DEFAULT false,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_questionnaire_submissions_result_check
    CHECK (result IN ('AUTO_GO', 'ADMIN_REVIEW_REQUIRED')),
  CONSTRAINT foster_questionnaire_submissions_parent_unique
    UNIQUE (organization_id, org_foster_parent_id)
);

CREATE INDEX IF NOT EXISTS idx_foster_questionnaire_submissions_org
  ON foster_questionnaire_submissions(organization_id);

CREATE TABLE IF NOT EXISTS foster_questionnaire_answers (
  id UUID PRIMARY KEY,
  submission_id UUID NOT NULL REFERENCES foster_questionnaire_submissions(id) ON DELETE CASCADE,
  question_id VARCHAR(16) NOT NULL,
  option_id VARCHAR(32),
  answer_value JSONB,
  candidate_note TEXT NOT NULL DEFAULT '',
  screening_outcome VARCHAR(32),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT foster_questionnaire_answers_submission_question_unique
    UNIQUE (submission_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_foster_questionnaire_answers_submission
  ON foster_questionnaire_answers(submission_id);

CREATE TABLE IF NOT EXISTS foster_matching_profiles (
  id UUID PRIMARY KEY,
  submission_id UUID NOT NULL UNIQUE REFERENCES foster_questionnaire_submissions(id) ON DELETE CASCADE,
  pf01 JSONB NOT NULL DEFAULT '{}'::jsonb,
  pf02 JSONB NOT NULL DEFAULT '{}'::jsonb,
  pf03 JSONB NOT NULL DEFAULT '{}'::jsonb,
  pf04 JSONB NOT NULL DEFAULT '{}'::jsonb,
  pf05 JSONB NOT NULL DEFAULT '{}'::jsonb,
  pf06 JSONB NOT NULL DEFAULT '{}'::jsonb,
  derived_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS foster_questionnaire_decisions (
  id UUID PRIMARY KEY,
  submission_id UUID NOT NULL REFERENCES foster_questionnaire_submissions(id) ON DELETE CASCADE,
  decision VARCHAR(64) NOT NULL,
  structured_reason TEXT NOT NULL DEFAULT '',
  staff_notes TEXT NOT NULL DEFAULT '',
  decided_by UUID REFERENCES users(id) ON DELETE SET NULL,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_foster_questionnaire_decisions_submission
  ON foster_questionnaire_decisions(submission_id, decided_at DESC);
