-- PR7: coarse device labels for account security (A1) notifications.

CREATE TABLE IF NOT EXISTS account_device_labels (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label text NOT NULL,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  session_family_id uuid
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_account_device_labels_user_label
  ON account_device_labels (user_id, label);

CREATE INDEX IF NOT EXISTS idx_account_device_labels_user_last_seen
  ON account_device_labels (user_id, last_seen_at DESC);
