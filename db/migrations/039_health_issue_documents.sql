-- W12: health issue document attachments (mirror health_event_photos)

CREATE TABLE IF NOT EXISTS health_issue_documents (
  id UUID PRIMARY KEY,
  health_issue_id UUID NOT NULL REFERENCES health_issues(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_health_issue_documents_issue_id
  ON health_issue_documents(health_issue_id);
