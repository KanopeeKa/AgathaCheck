---
title: Account erasure data map
owner: Privacy / Backend
audience: both
status: active
last_updated: 2026-10-04
tags: [privacy, erasure, gdpr]
---

# Account erasure data map

Machine-checkable inventory: [`erasure-data-map.json`](./erasure-data-map.json).  
Architecture acceptance rules: [ADR 0001](../../architecture/decisions/0001-account-erasure-acceptance.md).

## Synchronous database scope (D15)

Everything listed under `bindings` in the JSON map is in scope for the **acceptance transaction** (Package 5 / ARCH F phase 2). That includes:

- Every foreign key to `users(id)` in `public`, with `erasure_action` derived from PostgreSQL `ON DELETE` (`c` → cascade, `n` → set_null, `a`/`r` → explicit_delete handled before the user row is removed).
- Non-FK columns discovered by the same rules as the PG guard test (`user_id`, `*_user_id`, `*_by`, `*_by_user_id`, `email`, `invitee_email`).
- The `users.id` root row (`explicit_delete` after sessions are revoked and cleanup jobs are enqueued).
- `cleanup_jobs` rows scoped by `correlation_id` to the erasure operation (no FK to users).

Row deletes and cascades run inside the transaction; `set_null` and `explicit_delete` columns are updated or purged before `DELETE FROM users`.

## Asynchronous scope (files and PostHog)

Not held open in the DB transaction:

- **Files** — paths in `file_columns` (`uploads`, `private_health`). Identifiers are collected before cascades remove rows; `file_delete` jobs in `cleanup_jobs` perform verified deletion (D4).
- **PostHog** — `posthog_person_delete` job type; 2xx/404 succeed, retryable on outage; not configured → `not_configured` on status API.

Completion of erasure is **accepted** when the transaction commits; **completed** when all correlated jobs succeed.

## Retained data (lawful basis)

| Data | Treatment | Basis |
|------|-----------|--------|
| `audit_events` | Row retained; `actor_user_id` anonymised and actor-identifying fields stripped in the acceptance transaction | Legitimate interest / security audit trail without living identity |
| `organizations.email`, org branding files | Unchanged when only a member account is erased | Organisation is a separate controller context |
| Historical rows where FK is `set_null` | Event kept; user pointer cleared | Attribution minimisation |

Frozen foster/org schema fields called out in the active codebase review remain readable for compatibility; erasure does not silently drop retained DTO columns from installed clients.

## Shared pets and households

- **Household pets** — `DELETE /api/auth/me` keeps today’s **`409 household_pets_require_confirmation`** when the account still has household-owned pets without explicit confirmation (unchanged product rule).
- **Shared access** — `pet_access`, share invites, and absence carers are removed or unlinked via cascades and explicit steps in the map; other members’ pets and data are not deleted.

## GDPR export

`GET /api/auth/me/export` must continue to cover exportable personal data **before** erasure is accepted. Phase 2 adds no regression to export tests (F.2-11). Retained audit and org data follow existing export redaction rules.

## PEOPLE programme (planned)

`planned_tables` in the JSON documents bindings for migrations not yet on `main` (`people_contact_household_notes`, `household_invites`, `pet_share_invites.contact_id`). The PG guard test ignores them until the table exists; once migrated, they must move into `bindings`.

## Gaps (phases 2–3 owners)

| # | Gap | Owner | Notes |
|---|-----|-------|-------|
| 1 | Synchronous `DELETE /me` still purges files/PostHog before DB delete | ARCH F phase 2 | Replaced by 202 + jobs |
| 2 | Access JWTs valid until expiry after delete | ARCH F phase 3 | `account_unavailable` middleware (D17) |
| 3 | `foster_profiles` / `prospects` rows may retain email after `user_id` SET NULL until explicit redaction | ARCH F phase 2 erasure service | Map marks email `explicit_delete`; implementation must scrub |
| 4 | `archived_pets.transferred_to_user_id` has no FK | ARCH F phase 2 | Must NULL when transferee account erased |
| 5 | PEOPLE tables in `planned_tables` | PEOPLE server + ARCH F | Promote to `bindings` when migrations land |

If a gap cannot be closed in phases 2–3 within their allowed paths, halt with `governance_approval_required` on the batch F control issue.

## Verification

```bash
cd server && npx jest --env=node test/db/erasureDataMap.test.js --forceExit
```

The test compares live `pg_constraint` / `information_schema` discovery to `bindings` so new tables cannot ship without an erasure decision.
