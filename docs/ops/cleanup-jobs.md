---
title: Cleanup jobs operations
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [operations, jobs]
---
# Cleanup jobs (`cleanup_jobs`)

Durable, retryable background work for file deletion (and later required notifications). Jobs are stored in PostgreSQL with no foreign keys so they survive user and pet cascades.

## Runtime components

| Component | Role |
| --- | --- |
| In-process runner | Started from `server/bin/start.js`; polls every `CLEANUP_JOBS_POLL_MS` (default `60000`). Set `CLEANUP_JOBS_RUNNER=off` to disable. |
| `kickCleanupJobs()` | Exported from `server/bin/start.js` for an immediate drain after producers enqueue (future phases). |
| CLI | `node server/scripts/run-cleanup-jobs.js [--limit N]` — one-shot drain for cron (install cron in the ops plan). |

If the `cleanup_jobs` table is missing (`42P01`), the runner logs a warning once per poll interval and keeps the API process healthy until migrations apply.

## Inspecting jobs

```sql
SELECT id, job_type, status, attempts, max_attempts, next_attempt_at,
       correlation_id, last_error_redacted, created_at, completed_at
FROM cleanup_jobs
ORDER BY created_at DESC
LIMIT 50;
```

Payloads are cleared when a job succeeds; `dead` rows retain metadata until manually resolved.

## Manual retry (dead → pending)

Only after verifying the underlying issue (permissions, path, etc.):

```sql
UPDATE cleanup_jobs
SET status = 'pending',
    attempts = 0,
    next_attempt_at = now(),
    lease_token = NULL,
    lease_expires_at = NULL,
    last_error_redacted = NULL,
    completed_at = NULL,
    updated_at = now()
WHERE id = '<job-uuid>' AND status = 'dead';
```

Then run `node server/scripts/run-cleanup-jobs.js` or wait for the in-process runner.

## Alerts

| Signal | Owner |
| --- | --- |
| Log line `cleanup job reached dead status` (includes `jobId`, `jobType`, `correlationId`, never payload) | Backend on-call / platform |
| CLI exit code `1` from `run-cleanup-jobs.js` | Same — cron should surface non-zero exits |

Drain summaries log at info: `{ claimed, succeeded, retryable, dead }`.

## Rollback

- **Code rollback:** Safe while the table exists; pending rows remain and will drain when the runner returns.
- **Never** run `085_cleanup_jobs_down.sql` while `status IN ('pending','running','retryable')` rows exist — finish or requeue jobs first.
- `dead` rows are kept intentionally for inspection; delete only after manual review.

## Environment

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLEANUP_JOBS_RUNNER` | `on` | `off` disables the in-process runner |
| `CLEANUP_JOBS_POLL_MS` | `60000` | Poll interval (ms) |
| `CLEANUP_JOBS_LEASE_MS` | `300000` | Lease duration for a claimed job (ms) |
