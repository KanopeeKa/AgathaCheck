---
title: Account lifecycle (Node.js lib)
owner: Backend team
status: active
component_id: server.lib.account
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Account-level application services: **erasure acceptance** (D15–D17), security notifications, device labels, and session helpers used by auth routes. **Non-goals:** pet deletion (pets component), generic cleanup execution (jobs component).

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/lib/account/` |
| Primary API surface | `accountErasureService.js` — called from `server/routes/auth/profileRouter.js` |

## Owned data

`account_erasure_operations`, correlated `cleanup_jobs` rows, `users` (delete at acceptance), `refresh_sessions` (revoke).

## Public API (application)

| Operation | Inputs | Output | Errors | Transaction owner |
|-----------|--------|--------|--------|-------------------|
| `acceptAccountErasure` | user id, password, request metadata | `202` operation id + status token | 401, 409 household pets | `withTransaction` — locks user, enqueues jobs, deletes user |
| `getErasureStatus` | operation id + status token | step progress | 404 (wrong id/token) | read-only |
| Idempotent replay | same user | same `operation_id`, no new token | — | read existing operation |

Wire: [ADR 0001](../../../docs/architecture/decisions/0001-account-erasure-acceptance.md), [api-reference](../../../docs/architecture/api-reference.md).

## Side effects

- Enqueues `file_delete` and `posthog_person_delete` jobs before user row delete (ADR 0004).
- `kickCleanupJobs` after commit (runner in `server/bin/start.js`).
- Security push/email helpers for new-device flows (best-effort).

## Permissions

- Only the authenticated account owner may initiate erasure.
- Status token is capability-bearing; treat as secret.

## Tests

`server/test/auth/erasure.test.js`, `server/test/db/accountErasure.integration.test.js` (when present), erasure data-map PG guard.

## Operational notes

- Acceptance is not completion — monitor `cleanup_jobs` by `correlation_id`.
- Shared household pets: existing `409 household_pets_require_confirmation` unchanged.
