---
title: Active codebase Batch F — Resumable account erasure
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-f-account-erasure-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-f-account-erasure-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-f-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batch E merged to `main` (`cleanup_jobs`, runner, `TransactionAborted` guard) |
| **router risk** | R3 — protocols `security`, `authorization`, `data-lifecycle`, `private-files`, `database-and-migrations`, `api-contract`, `observability`, `testing`; integration review mandatory |

## Entry gate (coordination, `docs/agent-efficiency/parallel-programmes.md`)

- Landing slot **5a**. Bootstrap only after ARCH E (3a) **and** the PEOPLE server (`people-server-7f3b`, slot 4) have landed on `main`, because PEOPLE adds new personal-data tables that erasure must cover.

## Goal

Deliver Package 5 under D3, D4, D15, D16 and D17. Account deletion returns **202 Accepted** only after a durable acceptance transaction: the database is erased, sessions are revoked, and cleanup jobs for files and PostHog are queued. Pre-erasure access tokens are rejected immediately. Cleanup can resume after crashes, provider outages and retries without a live account, and every step is visible through a scoped status capability. The only pre-approved migration is `account_erasure_operations` (D9a).

Today's defect, for reference: `DELETE /api/auth/me` (`server/routes/auth/profileRouter.js:211-266`) purges files and calls PostHog **before** deleting the user row, swallows PostHog failures, and returns a synchronous 200. Access JWTs stay valid for up to 30 minutes.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: active
current_phase: 5
last_completed_phase: 4
halt_reason: null
next_action: "continue phase 5 on branch cursor/active-codebase-f-integration-e41f"
artifact_ref:
  branch: cursor/active-codebase-f-integration-e41f
  plan_path: .agents/plans/active-codebase-batch-f-account-erasure-e41f.md
  plan_commit: c9f8c5110d1bb925fbf3b5a77bc39e2bfc63fc16
  snapshot_path: .agents/plans/active-codebase-batch-f-account-erasure-e41f.snapshot.json
  snapshot_commit: c9f8c5110d1bb925fbf3b5a77bc39e2bfc63fc16
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Erasure data map and acceptance ADR

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-f1-erasure-data-map-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-f-account-erasure-e41f.*
docs/engineering/privacy/**
docs/architecture/decisions/**
docs/architecture/index.md
server/test/db/erasureDataMap*.test.js
server/test/db/helpers/**
```

**forbidden_paths:**

```
server/lib/**
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

**Scope:** a machine-checkable data map of everything tied to a user account, and ADR `0001` recording the acceptance boundary. The ADR also creates the `docs/architecture/decisions/` index.

**Acceptance criteria:**

- [ ] **F.1-1** `docs/engineering/privacy/erasure-data-map.json` lists every table (including the PEOPLE tables `people_contacts`, `people_contact_private_notes`, `people_contact_household_notes`, `household_invites`, `pet_share_invites.contact_id` and contact `linked_user_id` links) that has a FK to `users(id)` or a `user_id`, `*_user_id`, `*_by` or `email` column, with its erasure action (`cascade` \| `set_null` \| `explicit_delete` \| `retained` plus reason), and every file-bearing column with its storage kind.
- [ ] **F.1-2** A real-PG test, `server/test/db/erasureDataMap.test.js`, reads `pg_constraint`/`information_schema` and **fails** when a user FK or matching column is missing from the map, so a future table cannot silently escape erasure.
- [ ] **F.1-3** `erasure-data-map.md` states: the synchronous DB scope (D15); the async scope (files, PostHog); retained data with its lawful basis (for example, audit events with the actor anonymised); shared/household behaviour (the 409 confirmation is kept); frozen retained schema and GDPR export coverage; and any data that currently survives erasure, listed as a numbered gap with an owner.
- [ ] **F.1-4** ADR `docs/architecture/decisions/0001-account-erasure-acceptance.md` (with frontmatter and an index `README.md`) records the commit point, job types, status capability, token rejection and rollback rules (never restore erased data).
- [ ] **F.1-5** **Halt rule:** if F.1-3 lists a gap that phases 2–3 cannot fix inside their `allowed_paths`, halt with `governance_approval_required` and post the list on the control issue.

---

### Phase 2 — Erasure service, 202 contract and status capability

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-f2-erasure-service-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-f-account-erasure-e41f.*
db/migrations/*_account_erasure_operations.sql
db/migrations/*_account_erasure_operations_down.sql
server/lib/account/**
server/lib/jobs/handlers/posthogPersonDelete.js
server/lib/jobs/handlers/index.js
server/lib/posthogServer.js
server/lib/petDataLifecycle.js
server/routes/auth/profileRouter.js
server/routes/auth/index.js
server/test/auth/**
server/test/account/**
server/test/db/accountErasure*.test.js
server/test/migrations/*_account_erasure_operations.test.js
docs/architecture/api-reference.md
docs/architecture/openapi/pet-care-critical.json
docs/ops/account-erasure.md
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

**Scope:** `server/lib/account/accountErasureService.js`, the `account_erasure_operations` migration, the `posthog_person_delete` handler, the new `DELETE /me` flow, the status endpoint and the runbook.

**Acceptance criteria:**

- [ ] **F.2-1** An additive migration creates `account_erasure_operations`: `id`, `user_id` (no FK), `status` ∈ `accepted` \| `in_progress` \| `completed` \| `failed`, `status_token_hash`, `requested_at`, `db_erased_at`, `completed_at`, `failed_at`, `last_error_redacted`. The down migration drops only this table. Migration test up → down → up.
- [ ] **F.2-2** `DELETE /api/auth/me` (both prefixes) keeps today's validation order: 401 missing token → 400 missing or incorrect password → 409 `household_pets_require_confirmation`. It then runs **one** `withTransaction`:
  1. `SELECT … FOR UPDATE` on the user row and the owned pet rows.
  2. Collect storage ids for owned-pet files and the profile photo.
  3. Enqueue `file_delete` jobs and one `posthog_person_delete` job (dedupe `posthog:<user_id>`), all with correlation = operation id.
  4. Revoke refresh sessions.
  5. Insert the operation row.
  6. Delete the user row (existing cascades).
  7. Insert the audit row `auth.account_deletion_accepted` (actor_type `system`, no email), awaited.
  8. Commit, then `kickCleanupJobs()`.
- [ ] **F.2-3** The response is `202 { message: <non-empty string>, erasure: { operation_id, status: "accepted", status_token } }` (D16). The installed-client test asserts `message` is a string, because the shipped `AuthService.deleteAccount` reads only `message` and treats any status below 400 as success.
- [ ] **F.2-4** Real-PG fault injection at each transactional step returns 500 and leaves the user able to log in, with zero jobs, no files touched and PostHog not called.
- [ ] **F.2-5** A retry of `DELETE /me` with the **pre-erasure** access token after acceptance (lost response) returns 202 with the **same** `operation_id` and current status, **without** a `status_token`, and creates no new jobs.
- [ ] **F.2-6** `GET /api/auth/erasure/:operationId` with `X-Erasure-Status-Token` (both prefixes, no bearer needed) returns `{ operation_id, status, steps: { database: "completed", files: { total, succeeded, pending, dead }, analytics: "pending" | "completed" | "failed" | "not_configured" } }`. An unknown id and a wrong token both return the **same** 404 (constant-time comparison). The token is 32 random bytes stored only as SHA-256. The route has the same rate limiter as the auth routes.
- [ ] **F.2-7** Status derivation: `completed` once every correlated job has `succeeded` (sets `completed_at`); `failed` once any job is `dead` (sets `failed_at`, recoverable via the runbook retry); otherwise `in_progress`.
- [ ] **F.2-8** The `posthog_person_delete` handler maps 2xx and 404 to `succeeded`; 429, 5xx and network errors to `retryable`; 401/403 to `retryable`, then `dead` with an error log; not configured to `succeeded`, recorded as `not_configured`.
- [ ] **F.2-9** `purgePetFiles` and `purgeAllPetFilesForUser` are removed. No code path deletes files synchronously before the DB commit.
- [ ] **F.2-10** Profile-photo upload compensation: if the `users` update affects 0 rows because the user was erased, the newly written file is removed before responding (test).
- [ ] **F.2-11** The GDPR export (`GET /me/export`) tests pass unchanged.
- [ ] **F.2-12** `docs/ops/account-erasure.md` states that erasure is irreversible, how to find an operation's jobs and retry dead ones, what to do during a PostHog outage, and the rollback rule: code rollback keeps the tables and jobs, and personal data is never restored.

---

### Phase 3 — Reject pre-erasure access tokens and close upload races

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-f3-access-rejection-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-f-account-erasure-e41f.*
server/lib/auth/accountExistence.js
server/bin/server.js
server/lib/safeUpload.js
server/lib/privateHealthStorage.js
server/routes/pets/photoRouter.js
server/routes/healthEntries/shared.js
server/test/auth/accountExistence*.test.js
server/test/db/erasureRace*.test.js
docs/ops/observability.md
```

**forbidden_paths:**

```
server/routes/auth/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** the D17 middleware, plus compensation so that no orphan file is left when an upload races erasure.

**Acceptance criteria:**

- [ ] **F.3-1** A middleware mounted before every API router on `/api` and `/backend/api` runs `SELECT 1 FROM users WHERE id = $1` for each request whose bearer access token **verifies**. A missing user returns 401 `{ error: "Unauthorized", code: "account_unavailable" }`. Requests with no token or an invalid token pass through unchanged, so routes keep their current 401s. Exempt: `DELETE …/auth/me` and `GET …/auth/erasure/:id`.
- [ ] **F.3-2** With the pre-erasure access token after acceptance, a matrix test on **both prefixes** covering pets list (GET), health entry create (POST), pet photo upload and health file upload returns 401 `account_unavailable` every time, and no file is written to disk.
- [ ] **F.3-3** Race (real-PG, two connections): an upload whose DB insert is blocked by the erasure transaction's row locks fails after commit on its FK, and the route removes the written file before responding. No orphan file remains.
- [ ] **F.3-4** The middleware adds exactly one query per authenticated request (test); the cost is documented in `docs/ops/observability.md`.
- [ ] **F.3-5** Refresh and login for the erased account fail (existing session tests extended).

---

### Phase 4 — Client handling, BDD and E2E

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-f4-erasure-client-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-f-account-erasure-e41f.*
flutter_app/lib/features/auth/presentation/screens/my_details_screen.dart
flutter_app/lib/features/auth/data/auth_service.dart
flutter_app/lib/l10n/app_en.arb
flutter_app/lib/l10n/app_fr.arb
flutter_app/lib/l10n/app_localizations.dart
flutter_app/lib/l10n/app_localizations_en.dart
flutter_app/lib/l10n/app_localizations_fr.dart
flutter_app/test/features/auth/**
flutter_app/test/bdd/features/gdpr_data_rights.feature
e2e/playwright/tests/gdpr.data-rights.spec.ts
e2e/playwright/pages/my-details.page.ts
e2e/playwright/support/api.ts
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** handle 202 (and 200 from older servers), with truthful copy and no polling (D16), plus journey coverage.

**Acceptance criteria:**

- [ ] **F.4-1** `AuthService.deleteAccount` returns a typed result `{ message, operationId?, accepted }` for both 200 and 202; the error path for 4xx/5xx is unchanged.
- [ ] **F.4-2** On success the app logs out and navigates to `/landing`, showing a localized (EN + FR) message that the account is deleted and remaining files and analytics data are being removed. It never claims everything is already erased. Widget tests cover the 200 and 202 paths.
- [ ] **F.4-3** `gdpr.data-rights.spec.ts`: after deletion the landing message is visible; logging in with the old credentials fails; an API call with the pre-deletion access token returns 401 `account_unavailable` on both prefixes (via `support/api.ts`). The status endpoint, polled with the returned `status_token`, reaches `completed` within 60 s (files `succeeded`; analytics `completed` or `not_configured`). Gherkin scenario titles in `gdpr_data_rights.feature` match `@bdd` titles exactly; the BDD coverage, priority-tag and shard-manifest checks pass.
- [ ] **F.4-4** The UI does no status polling (D16).

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-f-integration-e41f` |
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

**Scope:** open one PR from the integration branch into `main`; integration review per `.cursor/agent-kernel/workers/integration-reviewer.md` (R3); `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **F.5-1** The integration review is posted on the PR, with no open must-fix items. The backend-integration (PostgreSQL) job is green.
- [ ] **F.5-2** Pre-UAT E2E is green on the merge SHA, including `gdpr.data-rights.spec.ts`.
- [ ] **F.5-3** The roadmap child status is `merged` and the Package 5 row reads Done. After the next UAT deploy, the migrate summary shows `account_erasure_operations` applied. This is a follow-up check recorded on the control issue, not a phase gate.
