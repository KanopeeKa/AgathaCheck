---
title: Health entries routes (Node.js)
owner: Backend team
status: active
component_id: server.routes.healthEntries
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

HTTP translation for health entries, schedules, occurrences, completions, documents, and absence context on `/api/health-entries` (and `/backend/api/health-entries`). **Non-goals:** planned absence CRUD (careContext mounts separately), weight-only entries (`weightEntries`).

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/routes/healthEntries/` |
| Domain logic | `server/lib/care/**`, `server/lib/health/**` |
| Mount | `server/routes/healthEntries.js` shim → `index.js` |

## Owned data (primary)

`health_entries`, occurrence/schedule tables, completion history, private health documents metadata, weight-establishment side tables touched by completion routes.

## Public API (selected)

| Area | Representative endpoints | Transaction owner |
|------|------------------------|-------------------|
| CRUD | `GET/POST/PUT/DELETE /health-entries` | services / `withTransaction` on multi-row writes |
| Schedule | `PUT …/schedule`, explain endpoints | `server/lib/care/schedule/**` |
| Occurrences | `GET …/occurrences`, patch, reschedule | occurrence use cases; some locks via `careItemLock` (deferral in ADR 0003) |
| Completion | `POST …/complete`, weight completion | `withTransaction` (weight side effects in-tx per D12) |
| Documents | upload/list/delete private files | storage + DB in service layer |

Errors: standard `401`/`403` access, `404` missing entry, `409` replay/conflict on idempotent completion. Calendar dates: `YYYY-MM-DD` on wire.

Client authority for mutations: [ADR 0005](../../../docs/architecture/decisions/0005-canonical-health-state-care-schedule-controller.md).

## Side effects

- Weight cache refresh and establishment inside completion transaction (D12).
- Audit events best-effort unless classified required in command matrix.
- Activity projections may update after commit.

## Permissions

Pet access capabilities (`can_log`, `full`, owner) enforced per entry/occurrence; absence guest context routes validate grant scope.

## Tests

`server/test/healthEntries.test.js`, `server/test/healthEntries/**`, `server/test/careSchedule/**`, `server/test/openapi/petCareContract.test.js`.

## Module layout

| Module | Responsibility |
|--------|----------------|
| `crud*Router.js` | Entry CRUD split by verb |
| `occurrencesRouter.js` / `occurrenceCommandRouter.js` | Lists and commands |
| `completionRouter.js`, `completeWeightRouter.js` | Completions |
| `scheduleRouter.js`, `documentsRouter.js` | Schedule and files |
| `absenceContextRouter.js` | Guest/absence-scoped reads |

Full reference: [api-reference.md](../../../docs/architecture/api-reference.md) § Health entries.
