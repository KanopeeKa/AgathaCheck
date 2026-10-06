---
title: Auth routes (Node.js)
owner: Backend team
status: active
component_id: server.routes.auth
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

HTTP translation for authentication, session lifecycle, profile, password reset, and account erasure entrypoints on `/api/auth` and `/backend/api/auth`. **Non-goals:** pet or health domain rules, subscription billing, cleanup job execution (see `server/lib/jobs/`).

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/routes/auth/` |
| Mount | `server/routes/auth.js` shim → `index.js` |
| Erasure service | `server/lib/account/accountErasureService.js` ([account README](../../lib/account/README.md)) |

## Owned data (primary tables)

`users`, `refresh_sessions`, `password_reset_tokens`, `account_erasure_operations` (erasure), audit events for auth actions.

## Public API (selected)

| Endpoint | Inputs | Output | Errors | Transaction owner |
|----------|--------|--------|--------|-------------------|
| `POST /signup`, `POST /login`, `POST /refresh`, `POST /logout` | credentials / refresh token | session tokens + user map | 400 validation, 401 auth | per-handler (single statements or service) |
| `GET/PATCH /me` | profile fields, timezone, weight_unit | user map | 401, 400 invalid unit | profile updates via service where multi-row |
| `DELETE /me` | password confirmation | **202** erasure envelope (D16) | 401, 409 household guard | `accountErasureService.acceptAccountErasure` (`withTransaction`) |
| `GET /erasure/:operationId` | header `X-Erasure-Status-Token` | operation + job progress | 404 constant-time | read-only |
| `POST /forgot-password`, `POST /reset-password` | email / token | message | 400, 429 rate limit | token tables |

Full wire detail: [api-reference.md](../../../docs/architecture/api-reference.md) · ADR [0001](../../../docs/architecture/decisions/0001-account-erasure-acceptance.md).

## Layer contract

| May depend on | Must not depend on |
|---------------|-------------------|
| `server/lib/account/**`, `server/lib/requireAuth.js`, `server/config/rateLimit.js` | `server/routes/pets/**` handlers directly |

## Side effects

- Erasure: enqueue `cleanup_jobs` inside acceptance transaction; revoke refresh sessions; access JWT rejection via global middleware (D17).
- Profile photo: storage uploads via shared upload helpers.
- Rate limits: `createAuthLimiter()` on sensitive routes.

## Permissions

- Bearer access token for protected routes; erasure and export require authenticated owner.
- Invalid or erased-user tokens → `401` `account_unavailable` (except exempt erasure poll/delete paths).

## Tests and gates

| Contract | Test path |
|----------|-----------|
| Session / profile | `server/test/auth.test.js`, `server/test/auth/profile.test.js` |
| Erasure | `server/test/auth/erasure.test.js`, real-PG erasure integration |
| Audit | `server/test/auth.audit.test.js` |

## Operational notes

- Both API prefixes must behave identically.
- Import path unchanged via `routes/auth.js` shim.
