---
title: Account erasure operations runbook
owner: Backend / Privacy
audience: both
status: active
last_updated: 2026-10-04
tags: [ops, privacy, erasure]
---

# Account erasure operations

Account deletion is **irreversible** once the acceptance transaction commits. Personal data is never restored from backups or manual SQL for erasure operations — roll back **application code** only.

## Acceptance vs completion

- **Accepted** — `DELETE /api/auth/me` returned `202` after the DB user row was removed, refresh sessions revoked, and `cleanup_jobs` enqueued (`file_delete`, `posthog_person_delete`).
- **Completed** — every correlated cleanup job is `succeeded` (see status API).

ADR: [0001-account-erasure-acceptance.md](../architecture/decisions/0001-account-erasure-acceptance.md).

## Finding an operation

```sql
SELECT id, user_id, status, requested_at, db_erased_at, completed_at, failed_at
FROM account_erasure_operations
ORDER BY requested_at DESC
LIMIT 20;
```

Correlated jobs:

```sql
SELECT id, job_type, status, attempts, max_attempts, last_error_redacted, next_attempt_at
FROM cleanup_jobs
WHERE correlation_id = '<operation_id>'
ORDER BY created_at;
```

## Status API (operators)

`GET /api/auth/erasure/:operationId` with header `X-Erasure-Status-Token` (same on `/backend/api/auth/...`). Wrong id and wrong token both return **404**.

## Retrying dead jobs

1. Inspect `last_error_redacted` on the dead row.
2. Fix the underlying issue (disk permissions, PostHog credentials, network).
3. Reset the job for retry:

```sql
UPDATE cleanup_jobs
SET status = 'retryable',
    attempts = 0,
    next_attempt_at = now(),
    lease_token = NULL,
    lease_expires_at = NULL,
    completed_at = NULL,
    last_error_redacted = NULL
WHERE id = '<job_id>' AND status = 'dead';
```

4. Ensure the cleanup runner is enabled (`CLEANUP_JOBS_RUNNER` not `off`) or restart the API pod to trigger `kickCleanupJobs()`.

## PostHog outage

- `posthog_person_delete` jobs move to `retryable` on 429/5xx and network errors; they become `dead` after `max_attempts`.
- Status `steps.analytics` stays `pending` until the job succeeds or fails.
- When PostHog is not configured in the environment, the handler records success and status shows `not_configured` — no outbound call.

## Code rollback

- Keep `account_erasure_operations` and `cleanup_jobs` tables and rows.
- Do **not** re-insert deleted users or restore files from object storage.
- After rollback, dead jobs may need manual retry (above).

## Duplicate delete requests

Clients may retry `DELETE /me` with the same access token after acceptance; the API returns `202` with the same `operation_id` and **no** new `status_token`, and does not enqueue duplicate jobs.
