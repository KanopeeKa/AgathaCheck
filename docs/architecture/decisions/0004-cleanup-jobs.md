---
title: "ADR 0004: Minimal cleanup jobs (D10 / D11)"
owner: Backend / Platform
audience: both
status: accepted
last_updated: 2026-10-06
tags: [architecture, jobs, adr]
adr: 0004
programme: active-codebase-batch-e-backend-integrity-e41f
---

# ADR 0004: Minimal cleanup jobs (D10 / D11)

## Status

**Accepted** — 2026-10-06 (Batch K phase 3). Schema and runner: Batch E phase 1; producers: E/F.

## Context

Pet and account deletion must survive process crashes while deleting files and external analytics identifiers. The review rejected a generic event bus (D4) but required durable, retryable work with lease semantics and bounded retention (review §Cross-cutting risks).

Roadmap decisions **D10** (runner shape) and **D11** (effect classification) bound what may use `cleanup_jobs` versus in-transaction writes.

## Decision

### D11 — What uses jobs

| Effect class | Mechanism |
|--------------|-----------|
| `file_delete` | Enqueue inside the acceptance/deletion transaction; drain after commit |
| `posthog_person_delete` | Same, for account erasure (ADR 0001) |
| In-app invite notification rows | **Same transaction** as invite create/accept — not a job |
| Passed-away collaborator notifications | **Same transaction** with `pet_lifecycle_notifications` ledger (D14) |
| Invitation email to new users | Best-effort delivery metadata after commit |
| Optional audit / activity | Best-effort, logged on failure |
| Required audit (pet delete, erasure acceptance) | In transaction, awaited before commit |

Only `file_delete` and `posthog_person_delete` are valid `job_type` values.

### D10 — Runner and lease

- Storage: PostgreSQL table `cleanup_jobs` with **no foreign keys** to users or pets (jobs survive cascades).
- Enqueue: `enqueueCleanupJob(client, …)` only on a checked-out client inside the producer transaction; idempotent on `dedupe_key`.
- Claim: `FOR UPDATE SKIP LOCKED`, status → `running`, fresh `lease_token` and `lease_expires_at` (`CLEANUP_JOBS_LEASE_MS`, default 5 minutes).
- Ack / fail: only the holder of the current `lease_token` may update; expired `running` rows are reclaimable.
- Status lifecycle: `pending` → `running` → `succeeded` | `retryable` | `dead` with bounded backoff (`cleanupJobsBackoff.js`).
- Execution: in-process runner in `server/bin/start.js` (poll + `kickCleanupJobs` after enqueue) plus one-shot CLI `server/scripts/run-cleanup-jobs.js`. No separate worker fleet.

### Retention

- On success: clear `payload` promptly; purge succeeded rows after **30 days** (`cleanupJobsHousekeeping.js`).
- `dead` rows remain for inspection until manually requeued or deleted (runbook: `docs/ops/cleanup-jobs.md`).

### Observability

- Log `cleanup job reached dead status` with `jobId`, `jobType`, `correlationId` (never raw payload).
- Erasure status API surfaces correlated job progress (ADR 0001).

## Consequences

- Producers must not delete the only copy of a storage identifier before enqueue commits.
- Code rollback is safe while pending rows exist; down-migrating the table with active jobs is forbidden.
- New asynchronous erasure work requires an ADR amendment — not an ad hoc queue.

## References

- [ADR 0001 — Account erasure acceptance](./0001-account-erasure-acceptance.md)
- [ADR 0003 — Transaction ownership](./0003-transaction-ownership.md)
- Operations: [cleanup-jobs.md](../../ops/cleanup-jobs.md)
- Component: [server/lib/jobs/README.md](../../../server/lib/jobs/README.md)
