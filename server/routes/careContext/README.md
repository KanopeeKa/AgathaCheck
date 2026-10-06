---
title: Care context routes (Node.js)
owner: Backend team
status: active
component_id: server.routes.careContext
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

HTTP translation for **planned absences**, absence care plans, handover, carer invites, and care-period coverage/projection APIs. Primary mount: `/api/planned-absences` (and `/backend/api/planned-absences`). Pet-scoped care period routes register via `registerCareContextPetRoutes` on the pets router.

**Non-goals:** health entry occurrence completion (healthEntries), people roster CRUD (`people/`).

## Location and entrypoint

| | Path |
|---|------|
| Production root | `server/routes/careContext/` |
| Use cases | `plannedAbsenceUseCases.js`, `server/lib/care/absence/**` |
| Mount | `server/routes/careContext/index.js` |

## Owned data (primary)

`planned_absences`, absence pets, resolutions, carer invites, care plan rows; links to people contacts (read-only projections).

## Public API (selected)

| Area | Endpoints | Transaction owner |
|------|-----------|-------------------|
| Absence CRUD | `POST/GET/PATCH/DELETE /planned-absences` | `plannedAbsenceUseCases` — `withTransaction` |
| Care plan | nested `/…/care-plan` routes | absence services |
| Handover / PDF | handover routes | mixed read + transactional writes |
| Carer invites | invite acceptance flows | transactional |
| Coverage / projection | pet-scoped period APIs | read-heavy + transactional updates |

Errors: `401`/`403` for declarer vs guest, `404` unknown absence, validation `400`. Timezone: absence stores declarer timezone at create (People D24).

## Side effects

- Notifications for absence events per product rules (in-transaction when required).
- Links to health reschedule suggestions (`away_planner` reason) — consumer is healthEntries.

## Permissions

Record owner and Full access (People D19); guest grants scoped to absence window.

## Tests

`server/test/careContext/**`, BDD `care_item_absence.feature`, E2E `care.item.absence.spec.ts`.

## Module layout

| Module | Responsibility |
|--------|----------------|
| `plannedAbsenceCoreRouter.js` | CRUD core |
| `plannedAbsencesRouter.js` | Composes sub-routers |
| `absenceCarePlanRouter.js`, `absenceResolutionsRouter.js` | Plan and resolutions |
| `plannedAbsenceHandoverRoutes.js`, `plannedAbsenceCarerInviteRoutes.js` | Handover and invites |
| `carePeriodProjectionRouter.js`, `carePeriodCoverageRouter.js` | Period views |

Reference: [api-reference.md](../../../docs/architecture/api-reference.md) § Planned absences.
