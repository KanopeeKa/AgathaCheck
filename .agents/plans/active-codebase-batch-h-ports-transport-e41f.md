---
title: Active codebase Batch H — Ports and transport boundaries
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-h-ports-transport-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-h-ports-transport-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-h-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **depends on** | Batches F and G merged (auth routes and health presentation are stable) |
| **router risk** | R3 for H.4 (auth) — protocols `security`, `authorization`, `api-contract`, `flutter-mobile`, `testing`; integration review mandatory |

## Goal

Deliver Package 10:

- Ports at real test and volatility seams: `AuthRepository`/`SessionStore` and `HealthDocumentsRepository`. Riverpod 2 and the `AuthNotifier` state machine are kept.
- One injected authenticated HTTP client as the only token/refresh authority.
- A central, Express 4-compatible async error boundary.
- Auth routers on the shared principal middleware, with token helpers moved out of `server/routes`, so `server/lib` no longer depends on routes.

No wire change. Every 401, 403 and 404 stays the same.

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
  plan_path: .agents/plans/active-codebase-batch-h-ports-transport-e41f.md
  plan_commit: null
  snapshot_path: .agents/plans/active-codebase-batch-h-ports-transport-e41f.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — AuthRepository and SessionStore ports (Flutter)

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-h1-auth-ports-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-h-ports-transport-e41f.*
flutter_app/lib/features/auth/**
flutter_app/lib/core/network/auth_http_client.dart
flutter_app/test/features/auth/**
flutter_app/test/core/network/**
scripts/feature-import-baseline.json
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/health_tracking/**
```

**allowed_exceptions:**

```
tests
file-split
```

**Acceptance criteria:**

- [ ] **H.1-1** `AuthRepository` (login, register, refresh, logout, deleteAccount, exportData, profile read/update, password change) and `SessionStore` (read, write, clear tokens) live in `features/auth/domain`. The implementations wrap `AuthService` and `TokenStore` in `features/auth/data`. `AuthNotifier` depends only on the ports, through providers, and its state machine and public API are unchanged.
- [ ] **H.1-2** No presentation file constructs `AuthService()` (today: `my_details_screen.dart:242` and `:305`), and no file outside `features/auth/data` imports `features/auth/data/**`. The feature-import baseline shrinks accordingly.
- [ ] **H.1-3** Tests with fakes cover login, logout, session restore and delete-account (F.4 behaviour). `auth_refresh_test.dart` (single-flight refresh plus request replay) passes unchanged.
- [ ] **H.1-4** `AuthHttpClient` stays the only refresh authority. A grep-based test fails if any new file under `flutter_app/lib` calls the refresh endpoint directly.

---

### Phase 2 — HealthDocumentsRepository port (Flutter)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-h2-health-documents-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-h-ports-transport-e41f.*
flutter_app/lib/features/health_tracking/data/**
flutter_app/lib/features/health_tracking/domain/**
flutter_app/lib/features/health_tracking/presentation/controllers/health_entry_form_controller_photos.dart
flutter_app/lib/features/health_tracking/presentation/providers/health_issue_providers.dart
flutter_app/lib/features/health_tracking/presentation/providers/health_providers.dart
flutter_app/lib/features/health_tracking/presentation/widgets/occurrence_add_details_sheet.dart
flutter_app/lib/features/health_tracking/presentation/widgets/health_issue_documents_strip.dart
flutter_app/lib/features/health_tracking/presentation/widgets/health_issue_card_body.dart
flutter_app/test/features/health_tracking/**
scripts/feature-import-baseline.json
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
flutter_app/lib/features/auth/**
```

**allowed_exceptions:**

```
tests
file-split
```

**Acceptance criteria:**

- [ ] **H.2-1** A `HealthDocumentsRepository` port (upload and remove for health-entry photos and health-issue documents, returning a typed `HealthDocument` with id and url, with typed failures) lives in `health_tracking/domain`. Its implementation in `data/` uses the injected authenticated HTTP client.
- [ ] **H.2-2** The duplicate datasource providers `healthRemoteDataSourceProvider` and `healthDataSourceProvider` are consolidated into one. The health data layer never builds `Authorization` headers by hand (grep test).
- [ ] **H.2-3** The five presentation files listed use the port; `health_tracking/presentation/**` never imports `health_tracking/data/**`.
- [ ] **H.2-4** Tests cover upload success; upload failure (4xx, 5xx and network, each mapped to a typed error); delete success and failure; and 401 → refresh → replay through the client.

---

### Phase 3 — Central async error boundary (server)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-h3-error-boundary-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-h-ports-transport-e41f.*
server/lib/http/**
server/bin/server.js
server/routes/pets/**
server/routes/healthEntries/**
server/routes/sharing/**
server/routes/careContext/**
server/routes/weightEntries.js
server/test/http/**
```

**forbidden_paths:**

```
server/routes/auth/**
server/routes/organizations/**
server/routes/fosterPlacements.js
server/routes/custodyTransfers.js
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
tests
docs
```

**Acceptance criteria:**

- [ ] **H.3-1** `server/lib/http/` provides typed errors (`ValidationError` 400, `UnauthenticatedError` 401, `ForbiddenError` 403, `NotFoundError` 404, `ConflictError` 409, `TransientError` 503), an Express 4-compatible `asyncHandler(fn)`, and a terminal error middleware. The middleware is registered after the routers on **both** prefixes, maps typed errors, redacts all others via `publicError`, includes `request_id`, and logs once.
- [ ] **H.3-2** Test: a handler that throws or rejects unexpectedly returns 500 JSON `{ error, request_id }` with no raw message in production mode, and never leaves the request hanging.
- [ ] **H.3-3** Every router in the listed directories uses `asyncHandler`. Per-route `try/catch` blocks that only map to 500 are removed. Existing route tests (status matrices 400/401/403/404/409) pass **unchanged**.
- [ ] **H.3-4** The existing security test is extended so that no 5xx body contains `err.message` or a stack in production mode for any migrated router.

---

### Phase 4 — Auth routers on the principal boundary (server)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-h4-auth-principal-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-h-ports-transport-e41f.*
server/routes/auth/**
server/lib/requireAuth.js
server/lib/authCookies.js
server/lib/refreshSessions.js
server/lib/auth/**
server/test/auth/**
server/test/requireAuth.test.js
server/test/architecture/serverDirection.test.js
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

**Acceptance criteria:**

- [ ] **H.4-1** Token sign/verify helpers move from `server/routes/auth/shared.js` to `server/lib/auth/tokens.js`. A new architecture test, `server/test/architecture/serverDirection.test.js`, fails if `server/lib/**` or `server/services/**` imports `server/routes/**`. Today there are 3 violations (`authCookies.js`, `refreshSessions.js`, `requireAuth.js`); afterwards there are 0.
- [ ] **H.4-2** Authenticated endpoints in `profileRouter`, `passwordRouter` and `sessionRouter` use `requireAuth` (principal on `req`). Unauthenticated-by-design flows (login, register, refresh, forgot and reset password) are unchanged. The deprecated `verifyToken` alias is removed.
- [ ] **H.4-3** Auth routers use `asyncHandler` and typed errors. A table-driven test records the 401/403/404/409 matrix for **every** auth endpoint on both prefixes, and the matrix is unchanged from before the phase (snapshot the matrix first, then refactor).
- [ ] **H.4-4** Session v2 tests (refresh rotation, reuse detection), the F.3 account-existence tests and the GDPR export tests pass unchanged.

---

### Phase 5 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/active-codebase-h-integration-e41f` |
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

**Scope:** open one PR from the integration branch into `main`; integration review (R3, auth); `./scripts/pre-push.sh`; `/babysit-uat`; pre-UAT watch; `complete-plan`; `roadmap-set-child`.

**Acceptance criteria:**

- [ ] **H.5-1** The integration review is posted with no open must-fix items. The authorization matrices are unchanged except for documented fixes.
- [ ] **H.5-2** Pre-UAT E2E is green on the merge SHA, including the login/logout, session-restore, health document upload and GDPR specs.
- [ ] **H.5-3** The roadmap child status is `merged`, and the Package 10 row reads Done.
