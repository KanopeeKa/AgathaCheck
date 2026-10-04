---
title: "ADR 0001: Account erasure acceptance boundary"
owner: Privacy / Backend
audience: both
status: accepted
last_updated: 2026-10-04
tags: [privacy, erasure, adr]
adr: 0001
programme: active-codebase-batch-f-account-erasure-e41f
---

# ADR 0001: Account erasure acceptance boundary

## Status

**Accepted** — 2026-10-04 (ARCH F phase 1). Implementation in phases 2–4.

## Context

Account deletion today (`DELETE /api/auth/me`) runs file purge, PostHog, and DB steps sequentially without a durable job model. Access JWTs remain valid after the user row is gone. D3/D4/D15–D17 in the [active codebase review](../reviews/active-codebase-review.md) require a defined **acceptance** commit point and resumable external cleanup.

## Decision

### Commit point

Erasure is **accepted** only after a single database transaction commits that:

1. Locks the user and owned pets (`SELECT … FOR UPDATE`).
2. Collects file storage identifiers and enqueues `cleanup_jobs` (`file_delete`, `posthog_person_delete`) with `correlation_id` = erasure operation id.
3. Revokes refresh sessions.
4. Inserts `account_erasure_operations` (phase 2 migration).
5. Deletes the `users` row (PostgreSQL cascades per [erasure data map](../../engineering/privacy/erasure-data-map.json)).
6. Inserts awaited audit `auth.account_deletion_accepted` (system actor, no email).

The HTTP response is **`202 Accepted`** with `operation_id`, `status: accepted`, and a one-time `status_token` (D16). **Acceptance is not completion.**

### Job types (minimal D4)

| `job_type` | Purpose |
|------------|---------|
| `file_delete` | Verified removal of upload / private_health objects |
| `posthog_person_delete` | Analytics person erasure (dedupe `posthog:<user_id>`) |

No generic event bus. Other notifications stay on existing patterns unless classified as required erasure work.

### Status capability

`GET /api/auth/erasure/:operationId` with header `X-Erasure-Status-Token` returns operation status and per-step progress (database completed; files and analytics from correlated jobs). Wrong id and wrong token return the same **404** (constant-time). Token is 32 random bytes, stored as SHA-256 only.

### Token rejection (D17)

After acceptance, **existing access JWTs** for the erased user id must be rejected on API routes (`401`, `code: account_unavailable`), not only refresh/login. Exempt: `DELETE …/auth/me` and erasure status poll. Implemented in ARCH F phase 3.

### Rollback

- **Personal data:** never restored once the acceptance transaction commits. Roll back **code** only; retain `account_erasure_operations` and `cleanup_jobs` rows.
- **Failed jobs:** retry via worker and runbook; `dead` jobs are visible on the status API and do not re-create the user account.
- **Duplicate delete:** idempotent `202` with same `operation_id`, no new `status_token`, no duplicate jobs.

## Consequences

- Clients must treat delete as asynchronous (phase 4 UI); installed clients keep reading `message` on 202 until updated.
- New user-linked tables must appear in `erasure-data-map.json` (PG guard test).
- Privacy export and household `409` confirmation behaviour are preserved.

## References

- [Erasure data map (human)](../../engineering/privacy/erasure-data-map.md)
- [Erasure data map (JSON)](../../engineering/privacy/erasure-data-map.json)
- Batch plan: `.agents/plans/active-codebase-batch-f-account-erasure-e41f.md`
