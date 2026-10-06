---
title: Cleanup jobs (Node.js lib)
owner: Backend / Platform
status: active
component_id: server.lib.jobs
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Durable background work for **file deletion** and **PostHog person deletion** (D10/D11). **Non-goals:** invite email delivery, weight cache rebuild, generic event bus.

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/lib/jobs/` |
| API | `cleanupJobsApi.js` — enqueue, claim, ack, fail |
| Runner | `cleanupJobsRunner.js` — started from `server/bin/start.js` |
| CLI | `server/scripts/run-cleanup-jobs.js` |

## Owned data

Table `cleanup_jobs` only (no FKs to users/pets).

## Public API (library)

| Function | Role | Transaction |
|----------|------|-------------|
| `enqueueCleanupJob(client, …)` | Insert idempotent job | Requires checked-out `client` inside producer tx |
| `claimCleanupJobs(pool, limit)` | Lease jobs | Own short transaction per claim batch |
| `acknowledgeCleanupJob` / `failCleanupJob` | Complete or retry | Lease token required |
| `drainCleanupJobs` / `kickCleanupJobs` | Process queue | Called post-commit |
| `runCleanupJobsHousekeeping` | 30-day retention | Periodic |

Statuses: `pending`, `running`, `succeeded`, `retryable`, `dead`.

## Side effects

- Filesystem deletes via `handlers/fileDelete.js` (path validation, idempotent missing file).
- PostHog API via `handlers/posthogPersonDelete.js`.
- Logs dead jobs; never logs raw payload secrets (`redactJobError.js`).

## Permissions

- Enqueue only from trusted producers inside authenticated transactions (pet delete, erasure).
- No public HTTP on jobs; operators use SQL + CLI (see ops runbook).

## Tests

`server/test/jobs/cleanupJobsRunner.test.js`, `server/test/jobs/fileDelete.test.js`, `server/test/db/cleanupJobs*.test.js`.

## Operational notes

Environment: `CLEANUP_JOBS_RUNNER`, `CLEANUP_JOBS_POLL_MS`, `CLEANUP_JOBS_LEASE_MS`.

Runbook: [docs/ops/cleanup-jobs.md](../../../docs/ops/cleanup-jobs.md). ADR: [0004](../../../docs/architecture/decisions/0004-cleanup-jobs.md).
