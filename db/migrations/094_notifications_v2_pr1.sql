-- Notifications v2 PR1: archived inbox rows + expanded kind taxonomy + legacy reclassify.

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_kind_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_kind_check
  CHECK (kind IN ('care', 'administrative', 'relationship', 'suggestion', 'account'));

CREATE INDEX IF NOT EXISTS idx_notifications_user_inbox_active
  ON notifications (user_id, created_at DESC)
  WHERE archived_at IS NULL;

-- Archive care reminder inbox rows (push/local only in v2).
UPDATE notifications
SET archived_at = COALESCE(archived_at, NOW())
WHERE type IN ('overdue', 'due_soon')
  AND archived_at IS NULL;

-- Relationship types (wire type → kind).
UPDATE notifications
SET kind = 'relationship'
WHERE archived_at IS NULL
  AND type IN (
    'shareInviteReceived',
    'shareInviteAccepted',
    'shareInviteDeclined',
    'householdInviteReceived',
    'absenceGuestGranted'
  );

-- Administrative wire types stored as care (legacy defaultKindForType gaps).
UPDATE notifications
SET kind = 'administrative'
WHERE archived_at IS NULL
  AND kind = 'care'
  AND type IN (
    'fosterRequestReceived',
    'fosterRequestResponded',
    'fosterInvitationReceived',
    'fosterApprovalGranted',
    'fosterApprovalDeclined',
    'sessionStartingSoon',
    'sessionEndingSoon',
    'agreementWithdrawn',
    'connectionRequestReceived',
    'pendingFosterPlacementReceived',
    'pendingAdoptionPlacementReceived',
    'pendingCustodyTransferReceived',
    'adminMessageReceived'
  );

-- Legacy `general` rows (stored as care) — title/message heuristics from spec §3.4.
UPDATE notifications
SET kind = 'relationship', type = 'ownershipTransferCompleted'
WHERE archived_at IS NULL
  AND type = 'general'
  AND (
    title ILIKE '%transfer%'
    OR message ILIKE '%now owned%'
    OR message ILIKE '%new owner%'
  );

UPDATE notifications
SET kind = 'relationship', type = 'petPassedAway'
WHERE archived_at IS NULL
  AND type = 'general'
  AND (
    title ILIKE '%loving memory%'
    OR title ILIKE '%passed away%'
    OR message ILIKE '%passed away%'
  );

UPDATE notifications
SET kind = 'relationship', type = 'shareAccessRemoved'
WHERE archived_at IS NULL
  AND type = 'general'
  AND (
    title ILIKE '%sharing ended%'
    OR message ILIKE '%stopped sharing%'
  );

UPDATE notifications
SET kind = 'relationship', type = 'shareMemberLeft'
WHERE archived_at IS NULL
  AND type = 'general'
  AND (
    title ILIKE '%stopped following%'
    OR message ILIKE '%stopped following%'
  );

UPDATE notifications
SET kind = 'relationship', type = 'shareLinkFollowed'
WHERE archived_at IS NULL
  AND type = 'general'
  AND (
    message ILIKE '%now following%'
    OR title ILIKE '%following%'
  );

UPDATE notifications
SET kind = 'administrative'
WHERE archived_at IS NULL
  AND kind = 'care'
  AND organization_id IS NOT NULL;

UPDATE notifications
SET kind = 'relationship'
WHERE archived_at IS NULL
  AND kind = 'care'
  AND type = 'general';

UPDATE notifications
SET kind = 'relationship'
WHERE archived_at IS NULL
  AND kind = 'care'
  AND pet_id IS NOT NULL;

UPDATE notifications
SET kind = 'administrative'
WHERE archived_at IS NULL
  AND kind = 'care';
