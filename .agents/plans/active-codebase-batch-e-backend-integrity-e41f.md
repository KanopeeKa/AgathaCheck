---
title: Active codebase Batch E — Backend integrity
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-e-backend-integrity-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-e-backend-integrity-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-e-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **router risk** | R3 (transactions, migration, file deletion) — protocols `database-and-migrations`, `data-lifecycle`, `private-files`, `api-contract`, `testing`, `observability` |

## Goal

Finish Packages 3, 4 and 6 as the review's exit gates define them:

- Durable, retryable file cleanup (`cleanup_jobs`, D10/D11).
- Pet deletion that is atomic end to end, with truthful counts (D13).
- One transaction helper across active server code.
- Stable, replay-safe invite and weight commands (D12, D22).
- Passed-away notifications that are never duplicated (D14).

Pre-approved migrations (D9a): `cleanup_jobs` and `pet_lifecycle_notifications` only. Use the next free migration numbers in `db/migrations/` at implementation time (083+ as of 2026-09-29).

**Real-PG test rule for this batch:** every real-PostgreSQL test lives under `server/test/db/**`, the only directory the CI `backend-integration` job runs. It uses a shared helper that **fails** (instead of silently returning) when `CI=true` and the database is unreachable.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: "bootstrap: create integration branch + control issue, then phase 1"
artifact_ref:
  branch: null
  plan_path: .agents/plans/active-codebase-batch-e-backend-integrity-e41f.md
  plan_commit: null
  snapshot_path: .agents/plans/active-codebase-batch-e-backend-integrity-e41f.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Cleanup jobs table and runner

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-e1-cleanup-jobs-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-e-backend-integrity-e41f.*
db/migrations/*_cleanup_jobs.sql
db/migrations/*_cleanup_jobs_down.sql
server/lib/jobs/**
server/scripts/run-cleanup-jobs.js
server/bin/start.js
server/test/jobs/**
server/test/db/cleanupJobs*.test.js
server/test/db/helpers/**
server/test/migrations/*_cleanup_jobs.test.js
docs/ops/cleanup-jobs.md
docs/ops/observability.md
```

**forbidden_paths:**

```
server/routes/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** additive `cleanup_jobs` schema, a job API, the `file_delete` handler, an in-process runner, a one-shot CLI and a runbook. No producer uses it yet.

**Acceptance criteria:**

- [ ] **E.1-1** An additive migration creates `cleanup_jobs` with these columns: `id` uuid (generated in code), `job_type`, `dedupe_key` UNIQUE, `correlation_id` uuid NULL, `payload` jsonb, `status` CHECK in (`pending`, `running`, `succeeded`, `retryable`, `dead`), `attempts`, `max_attempts`, `next_attempt_at`, `lease_token`, `lease_expires_at`, `last_error_redacted`, `created_at`, `updated_at`, `completed_at`. It adds indexes on (`status`, `next_attempt_at`) and on `correlation_id`. There is **no foreign key** to any table, so jobs survive user and pet cascades. The down migration drops only this table. The migration test runs up → down → up.
- [ ] **E.1-2** `enqueueCleanupJob(client, { type, dedupeKey, correlationId, payload })` rejects a `Pool` (it requires a checked-out client, so enqueueing happens inside the caller's transaction). It is idempotent on `dedupe_key` and returns the existing id.
- [ ] **E.1-3** Claiming is atomic (`FOR UPDATE SKIP LOCKED`) and sets `running`, a fresh `lease_token` and `lease_expires_at`. A real-PG test has two concurrent claimers drain 20 jobs, and each job is claimed exactly once.
- [ ] **E.1-4** Only the current lease holder can acknowledge or fail a job; a stale token is a no-op that returns `false`. Expired leases are reclaimable. A real-PG test that claims a job, never acknowledges it and lets the lease expire sees the job re-run exactly once more.
- [ ] **E.1-5** A retryable error sets `retryable`, increments `attempts` and schedules `next_attempt_at` on backoff 1m, 5m, 30m, 2h, 6h, 12h, 24h (default `max_attempts` 8). Exhausting attempts sets `dead`; a non-retryable error sets `dead` immediately. A test proves `last_error_redacted` never contains absolute paths, tokens or email addresses.
- [ ] **E.1-6** The `file_delete` payload is `{ storage: "uploads" | "private_health", relative_path }`. The handler resolves the path strictly under the configured root. Absolute paths, `..`, NUL bytes and symlinks that resolve outside the root make the job `dead` with no unlink. A missing file counts as `succeeded`; `EACCES`/`EPERM`/`EBUSY` are `retryable`. There is one test per case.
- [ ] **E.1-7** The runner starts from `server/bin/start.js` (not `server.js`, so importing the app in tests never starts it). It polls every `CLEANUP_JOBS_POLL_MS` (default 60000), exposes `kickCleanupJobs()` for an immediate drain, stops on SIGTERM/SIGINT before `pool.end()`, and is disabled when `CLEANUP_JOBS_RUNNER=off`. If the table does not exist yet (`42P01`, i.e. the code deployed before the migration), the runner logs one warning per poll interval and keeps the server running (test).
- [ ] **E.1-8** `node server/scripts/run-cleanup-jobs.js [--limit N]` drains due jobs once. It exits 0, or 1 if the run produced any `dead` job. Its cron usage is documented, with installation left to the ops plan (Step 3).
- [ ] **E.1-9** Housekeeping nulls the `payload` of `succeeded` jobs and deletes them after 30 days. `dead` jobs are kept until resolved manually.
- [ ] **E.1-10** Every drain logs `{ claimed, succeeded, retryable, dead }`. A transition to `dead` logs at error level with id, type and correlation id, and never the payload. `docs/ops/cleanup-jobs.md` covers how to inspect jobs, manual retry (a documented SQL snippet), the alert owner, and rollback (never drop the table while pending rows exist). `docs/ops/observability.md` links to it.
- [ ] **E.1-11** Runtime behaviour is otherwise unchanged: no producer enqueues yet, and all existing jest suites pass.

---

### Phase 2 — Atomic pet lifecycle commands (pet delete, data delete, passed-away)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-e2-pet-lifecycle-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-e-backend-integrity-e41f.*
server/lib/petDataLifecycle.js
server/lib/db/withTransaction.js
server/routes/pets/lifecycleRouter.js
server/routes/pets/coreRouter.js
db/migrations/*_pet_lifecycle_notifications.sql
db/migrations/*_pet_lifecycle_notifications_down.sql
server/test/lib/petDataLifecycle*.test.js
server/test/lib/withTransaction.test.js
server/test/db/petDataLifecycle*.test.js
server/test/db/petLifecycle*.test.js
server/test/db/withTransaction*.test.js
server/test/pets/**
server/test/openapi/**
server/test/migrations/*_pet_lifecycle_notifications.test.js
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** make `DELETE /api/pets/:id/data`, `DELETE /api/pets/:id` and `POST /api/pets/:id/passed-away` single-transaction commands; move file removal to `file_delete` jobs; D13 DTO; D14 dedupe; fix the COMMIT-as-ROLLBACK hole.

**Acceptance criteria:**

- [ ] **E.2-1** `withTransaction` throws a typed `TransactionAbortedError` when the `COMMIT` result's `command` is not `COMMIT`, which happens when Postgres turned it into a ROLLBACK because an earlier statement failed and its error was swallowed. Covered by a mock unit test and a real-PG test that swallows an in-transaction statement error.
- [ ] **E.2-2** `DELETE /pets/:id/data` and `DELETE /pets/:id` each run as **one** `withTransaction`, in this order:
  1. Collect storage identifiers.
  2. Enqueue one `file_delete` job per file (dedupe `file:<storage>:<relative_path>`, correlation = pet id).
  3. Delete dependent rows.
  4. Delete the pet row (pet delete only).
  5. Insert the required audit row (`pet.data_deleted` / `pet.deleted`), **awaited** on the same client.
  6. Commit, then `kickCleanupJobs()`.

  A rotating-pool test, where `pool.query` throws, proves no pool query runs inside either command.
- [ ] **E.2-3** Real-PG fault injection at every step (each table delete, the pet row delete, the audit insert, the job enqueue) leaves all rows, the pet and its file references intact, with zero jobs and zero files removed. The client is released (the pool's idle count is restored) and the route returns 500 with a public error message.
- [ ] **E.2-4** Files are removed only by the runner after commit. A real-PG test sees the job reach `succeeded` and the file disappear. A permission failure makes the job `retryable` while the HTTP response stays 200.
- [ ] **E.2-5** The response (D13) on both prefixes is `{ deleted: true, pet_id, rows_removed, files_scheduled, file_cleanup, files_removed }`, with `files_removed` documented as a deprecated alias of `files_scheduled`. OpenAPI and `api-reference.md` are updated, and the misleading "Lifecycle stubs" paragraph in `api-reference.md` is removed.
- [ ] **E.2-6** The `pet.deleted` audit is no longer written **before** the outcome is known; a failed deletion writes no success audit.
- [ ] **E.2-7** Passed-away (D14): an additive `pet_lifecycle_notifications (pet_id, event, recipient_user_id, notified_at, PRIMARY KEY (pet_id, event, recipient_user_id))` table, with a FK to `pets` ON DELETE CASCADE. Recipient selection, ledger inserts (`ON CONFLICT DO NOTHING RETURNING`) and notification rows happen in one transaction. A repeat POST, or two concurrent POSTs (real-PG test), produce no duplicate notifications. The response is `{ notification_sent, pet_id, notified_count, already_notified_count, delivery_status }`, with `delivery_status` ∈ `delivered` \| `already_notified` \| `no_recipients`. Recipients whose access is hidden or revoked at write time are excluded.
- [ ] **E.2-8** A POST to `passed-away` never modifies the `pets` row (GET before and after compared in a test); persistence remains `PUT /api/pets/:id`.
- [ ] **E.2-9** The A1 characterization tests for these flows are replaced by regression tests, and the baseline README rows are updated. Installed-client note: Flutter reads only `notified_count` (passed-away) and ignores the delete response body, so no client change is needed.

---

### Phase 3 — One transaction helper across active server code

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-e3-tx-consolidation-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-e-backend-integrity-e41f.*
server/lib/db/withOptionalTransaction.js
server/lib/petActivity.js
server/lib/care/progression/careMilestoneService.js
server/routes/careContext/plannedAbsencesRouter.js
server/routes/pets/shared.js
server/routes/pets/transferRouter.js
server/routes/pets/peopleRelationshipsRouter.js
server/routes/sharing/petAccessRoutes.js
server/test/architecture/**
server/test/helpers/**
server/test/db/plannedAbsence*.test.js
```

**forbidden_paths:**

```
server/routes/organizations/**
server/routes/fosterPlacements.js
server/routes/custodyTransfers.js
server/lib/fosterInvite.js
server/lib/orgPermissions.js
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** migrate active hand-written `BEGIN`/`COMMIT` blocks and all three `withOptionalTransaction` copies (`server/lib/db/`, `routes/pets/shared.js`, the local copy in `routes/pets/transferRouter.js`) to `withTransaction`; add an executable ownership rule.

**Acceptance criteria:**

- [ ] **E.3-1** A new architecture test, `server/test/architecture/transactionOwnership.test.js`, fails on `query('BEGIN')`, `query("BEGIN")` or `withOptionalTransaction` anywhere in `server/**` except `server/lib/db/withTransaction.js`, `server/scripts/**`, `server/db/seeds/**`, manifest frozen `serverRoots`, and the frozen lib files `server/lib/fosterInvite.js` and `server/lib/orgPermissions.js`. It ships with a **temporary allowlist naming exactly** the phase-4 files (`server/services/sharing/shareInviteService.js`, `server/services/sharing/shareLinkService.js`, `server/routes/healthEntries/completeWeightRouter.js`, `server/routes/weightEntries.js`).
- [ ] **E.3-2** All three `withOptionalTransaction` copies are deleted. Tests use a shared mock pool with `connect()` (`server/test/helpers/`), and no pool-only fallback remains in active code.
- [ ] **E.3-3** Existing suites for planned absences, care milestones, people relationships, pet access, individual transfer and pet activity pass, with only mock-setup changes. A real-PG test for planned-absence create proves rollback on an injected failure.
- [ ] **E.3-4** No response shape changes; the existing contract and route tests pass unchanged.

---

### Phase 4 — Stable, replay-safe invite and weight commands

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-e4-command-results-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-e-backend-integrity-e41f.*
server/services/sharing/**
server/db/sharing/**
server/routes/healthEntries/completeWeightRouter.js
server/routes/weightEntries.js
server/lib/care/progression/weightEstablishmentService.js
server/lib/petWeightSync.js
server/test/architecture/transactionOwnership.test.js
server/test/sharing/**
server/test/healthEntries/**
server/test/db/shareInvite*.test.js
server/test/db/shareLink*.test.js
server/test/db/weightCompletion*.test.js
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** invite create, accept, decline, revoke and share links, and weight completion and weight entry writes, all on `withTransaction`, following D11, D12 and D22; remove the phase-3 temporary allowlist.

**Acceptance criteria:**

- [ ] **E.4-1** Invite creation wraps each code attempt in a `SAVEPOINT`, so a unique-code collision (`23505`) retries without aborting the transaction. Test: forcing a collision on the first attempt returns 201 with a different code, with no `25P02` and no 500.
- [ ] **E.4-2** Creation is serialized per (inviter, lower(email)) with `pg_advisory_xact_lock`, and the access and pending-invite checks re-run inside the transaction. Real-PG test: two concurrent identical creates produce exactly one invite, and the other request gets the replay response.
- [ ] **E.4-3** Replay (D22): an identical request while a pending invite from the **same inviter** covers every requested pet returns 200 with the existing `invite_id`/`code` and `replayed: true`, with no new rows and no new notification. A different inviter never receives another inviter's code; they keep today's `excluded[]` with `pending_invite_exists`. Partial overlap keeps 201 plus `excluded[]`; the all-excluded non-replay case keeps 400.
- [ ] **E.4-4** In-app invite notifications for existing users are inserted **in the same transaction** (D11). Inviter and pet display names are read inside the transaction before commit. Fault injection at the notification insert persists no invite and returns 500. After commit, no code path can turn the response into an error.
- [ ] **E.4-5** New-user invitation email stays best-effort after commit, with `delivery.email` ∈ `sent` \| `failed` \| `skipped`. A failure is logged with the invite id and **without** the email address; the response is 201 either way.
- [ ] **E.4-6** Accept, decline, revoke and share-link redemption use `withTransaction` and lock the invite or link row with `FOR UPDATE`. Real-PG tests: a concurrent double accept produces one `pet_access` grant; accept after revoke or expiry keeps its existing 4xx; racing accept against revoke never grants access on a revoked invite.
- [ ] **E.4-7** Weight completion (D12): the weight-establishment evaluation and insert and `refreshPetWeightCache` run on the transaction client. Fault injection in either rolls back with 500 and no weight entry. Post-commit audit and activity failures are logged (warn, with action and ids) and never change the 201/200. The silent `.catch(() => {})` is removed.
- [ ] **E.4-8** Weight replay semantics are unchanged: a semantically equal replay returns 200 with the same observation, and a different payload returns 409. Real-PG test: concurrent identical completions produce one `weight_entries` row.
- [ ] **E.4-9** The weight create and update transaction in `server/routes/weightEntries.js` moves to `withTransaction`, with the same in-transaction cache and establishment handling.
- [ ] **E.4-10** The temporary allowlist in `transactionOwnership.test.js` is **empty**; no active file keeps a hand-written transaction.
- [ ] **E.4-11** The only response change is the additive `replayed` flag, documented in OpenAPI and `api-reference.md`. Installed-client note: Flutter treats any status below 400 as success and reads the same body fields, so a 200 replay works unchanged.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-e-integration-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
**
```

**forbidden_paths:**

```
.github/workflows/deploy-*.yml
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** open one PR from the integration branch into `main`; `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan`; `roadmap-set-child`. **Deploy order:** the migrations are additive and ship with the code. After the UAT deploy, confirm its migrate summary (`migrate_auto_applied` / `migrate_pending_count`) shows both new migrations applied. Prod promotion follows the existing prod migration procedure; producers fail safely (500 plus rollback) until the table exists.

**Acceptance criteria:**

- [ ] **E.5-1** Phases 1–4 are merged into the integration branch, and the integration → `main` PR is merged by `/babysit-uat` with the backend-integration (PostgreSQL) job green.
- [ ] **E.5-2** Pre-UAT E2E is green on the merge SHA, including the pet delete, sharing/invite and weight-completion specs in the shard manifest.
- [ ] **E.5-3** The roadmap child status is `merged`, and the review doc's Implementation status rows for Packages 3, 4 and 6 read Done.
