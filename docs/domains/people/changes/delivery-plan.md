---
title: People & Care Team — delivery plan
owner: Product / Documentation
audience: agent
status: active
last_updated: 2026-09-28
tags: [people, delivery]
---

# People & Care Team — delivery plan

Execute-plans:

- **Backend:** `people-care-team-a58d` (control #1343)
- **Nav + list hub:** `people-ui-hub-a58d` (control #1373) — merged to `main`
- **Hub UX remodel:** `people-hub-remodel-a58d` (control #1386) — cards, detail, edit, unified add, E2E

Canonical behaviour: [people-care-team.md](../features/people-care-team.md).

## UX remodel phase map (`people-hub-remodel-a58d`)

| Phase id | Outcome | Primary paths |
|----------|---------|---------------|
| p0-docs | Doc set aligned with remodel | `docs/domains/people/**` |
| p1-roster-cards | Cards + `/pc/people/:id` | `flutter_app/lib/features/people/**`, desk module |
| p2-detail-edit | View/edit + danger zone | `flutter_app/lib/features/people/**` |
| p3-unified-add | Add flow + sharing | `people/**`, `sharing/**`, `server/routes/people/**` |
| p4-tests-e2e | BDD + Playwright | `people.feature`, `e2e/playwright/**` |
| p5-ship-main | Integration → `main` | pre-UAT green |

## Backend phase map

| Product phase | Execute-plan id | Branch (target) | Primary ownership |
|---------------|-----------------|-------------------|-------------------|
| Docs on main | `land-docs` | `cursor/people-docs-land-a58d` → `main` | `docs/domains/people/**` |
| 0 Model settled | `p0-model` | `cursor/people-p0-model-a58d` | `db/migrations/072_*`, api-reference planned shapes |
| 1 Contacts v1 | `p1-contacts` | `cursor/people-p1-contacts-a58d` | `server/routes/people/`, `flutter_app/lib/features/people/`, vet migration |
| 2 Absence integration | `p2-absence` | `cursor/people-p2-absence-a58d` | `plannedAbsencesRouter.js`, away plan UI, `amends-away-planning.md` migration |
| 3 Households | `p3-households` | `cursor/people-p3-households-a58d` | new household tables, `petAccess.js` evaluation, sharing UI |
| 4 Guest access + TZ | `p4-guest-access` | `cursor/people-p4-guest-a58d` | `profileRouter.js`, absence invite flow, D24 columns |

Phase 5 (later) is out of scope for `people-care-team-a58d`.

## File ownership (parallel guardrails)

| Path | Phase | Notes |
|------|-------|-------|
| `db/migrations/072_*` | p0 | Contact foundation only — no vet row moves |
| `db/migrations/073_*` (vet backfill) | p1 | Data migration from `vets` / `pets.vet_id` |
| `server/routes/people/**` | p1 | New router; do not fold into `vets.js` long term |
| `server/routes/vets.js` | p1 | Thin compat shim until clients switch |
| `server/routes/careContext/plannedAbsencesRouter.js` | p2 | Contact carer ids + readiness `unavailable` |
| `server/lib/petAccess.js` | p3 | Household grant evaluation (read-time) |
| `flutter_app/lib/features/people/**` | p1+ | New feature root |
| `flutter_app/lib/features/sharing/**` | p3 | Who has access, household flows |

## API milestones

| Milestone | Phase | Endpoints (indicative) |
|-----------|-------|------------------------|
| Contact CRUD (personal directory) | p1 | `GET/POST /api/people/contacts`, `GET/PATCH/DELETE /api/people/contacts/:id` |
| Pet relationships | p1 | `GET/PUT /api/pets/:id/people-relationships` |
| Carer from contact | p2 | Extend `PATCH /api/planned-absences/:id` `pet_carers[].contact_id` |
| Readiness unavailable | p2 | `pet_carers[].carer_state` + `carer_coverage.unavailable_pet_ids` |
| Households | p3 | `POST /api/households`, membership, pet share into household |
| Absence guest access | p4 | `POST /api/planned-absences/:id/carer-invites` |
| Account timezone | p4 | `PATCH /api/me` `timezone`; absence `timezone` column |

## BDD

| Feature file | Phase |
|--------------|-------|
| `people.feature` (new) | p1 |
| `veterinarian_management.feature` | p1 (vet → contact) |
| `away_planning.feature`, `away_plan_detail_v2.feature` | p2 |
| `sharing.feature` | p3 |
| `notifications.feature` | p4 (D21/D25 prefs) |

## Doc branch cleanup

Spec landed via PR #1344 (`main`). Branch `claude/friendly-hopper-la0gx7` is superseded — no further merges required.
