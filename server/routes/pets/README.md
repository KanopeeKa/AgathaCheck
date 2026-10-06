---
title: Pet routes (Node.js)
owner: Backend team
status: active
component_id: server.routes.pets
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

HTTP translation for pet CRUD, access, transfers, lifecycle (passed-away, data delete), tags, and people links on `/api/pets` and `/backend/api/pets`. **Non-goals:** health entry schedules (healthEntries), planned absences (careContext), org shelter APIs when frozen gate is off.

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/routes/pets/` |
| Commands | `server/lib/pets/petCoreCommandService.js`, `server/lib/petDataLifecycle.js` |
| Mount | `server/routes/pets.js` shim |

## Owned data (primary)

`pets`, `pet_access`, `pet_photos`, lifecycle notification ledger `pet_lifecycle_notifications`, related audit rows. Retained org/foster columns may exist for compatibility (ADR 0006).

## Public API (selected)

| Endpoint | Inputs | Output | Errors | Transaction owner |
|----------|--------|--------|--------|-------------------|
| `GET /all`, `GET /`, `GET /:id` | auth | pet DTOs | 401, 404 | read-only |
| `POST /`, `PUT /:id` | pet body; `organization_id` blocked when frozen off | pet map | 400 frozen org id, 403 | `petCoreCommandService` / `withTransaction` |
| `DELETE /:id` | owner | D13 deletion summary | 403 | `withTransaction` + `kickCleanupJobs` |
| `DELETE /:id/data` | capability | D13 summary | 403 | same |
| `POST /:id/passed-away` | lifecycle payload | D14 notification counts | 403 | `withTransaction` + ledger |
| `POST /:id/transfer` | target user | transfer result | 403, 404 | service transaction |
| `POST /:id/transfer-to-org` | org id | — | **404** when frozen off | gated (ADR 0006) |

OpenAPI subset: [pet-care-critical.json](../../../docs/architecture/openapi/pet-care-critical.json).

## Side effects

- File cleanup jobs enqueued before destructive commits (ADR 0004).
- Passed-away and deletion: required in-app notifications inside transaction (D11).
- Frozen seam: `rejectFrozenOrganizationIdOnPetWrite`, `rejectFrozenShelterApi` on org transfer.

## Permissions

`userOwnsPet`, `petAccess` capabilities, share/collaborator rules on access routes.

## Tests

`server/test/pets.test.js`, `server/test/db/petLifecycle.integration.test.js`, `server/test/pets/frozenRouteGate.test.js`, OpenAPI contract tests.

## Module layout

| Module | Responsibility |
|--------|----------------|
| `shared.js` | Auth extraction, pet row mapping, transaction helpers |
| `coreListRouter.js` / `coreWriteRouter.js` | List and CRUD |
| `lifecycleRouter.js` | Passed-away and data delete |
| `transferRouter.js` | User and org transfer |
| `accessRouter.js` | Share links and collaborators |
| `index.js` | Composes routers (specific paths before `/:id`) |
