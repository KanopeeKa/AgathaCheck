---
title: Away Planning V1
plan_id: away-planning-v1
---

# Away Planning V1

| Field | Value |
|-------|-------|
| **plan_id** | `away-planning-v1` |
| **title** | Away Planning V1 (AW-0 through AW-10) |
| **base_branch** | `cursor/away-planning-v1-integration-5176` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Evolve `care_context` from a pull-only preview wizard into Away Planning: hub, per-absence plan page, per-pet carer model, derived readiness, and a printable carer handover. Context, people, projection and handover only — scheduling stays with Care Schedule Management.

**Canonical docs:** `docs/domains/pet_care/changes/away-planning-delivery-plan.md`
**Proposed decisions:** `docs/domains/pet_care/changes/away-planning-decisions.md`

## Autonomy

**NOT APPROVED.** No snapshot is committed for this plan, so `/execute-plan` cannot gate on it.

| Field | Value |
|-------|-------|
| **approved_at** | — |
| **approved_until** | — |
| **approved_by** | — |
| **autonomy** | not requested |
| **control_issue** | not created |

Before this plan may run, a human must: mark D-AWAY-001 through D-AWAY-012 `Frozen` (resolving the open problems in D-AWAY-002, D-AWAY-005, D-AWAY-009 and D-AWAY-012), open a control issue, and author `away-planning-v1.snapshot.json` validated by `node scripts/validate_execute_plan_snapshot.js --fix-hash`.

## Phases

Phases AW-0, AW-1, AW-2 and AW-3 are mutually independent and may run in parallel. AW-4 depends on AW-0. AW-5 through AW-10 are strictly sequential after AW-4. AW-SEED runs parallel to AW-5+ once AW-4 has merged.

### Phase aw-0 — Backend hygiene in careContext

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw0-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/routes/careContext/**
server/lib/care/plannedAbsence.js
server/lib/db/**
server/test/careContext/**
server/test/pets/helpers.js
```

**Exit criteria:**

- [ ] Read routers return a redacted 500 instead of hanging (`publicError` signature misuse)
- [ ] `GET /` batched to two queries; query count asserted
- [ ] `POST` / `PATCH` transactional; forced mid-write failure rolls back
- [ ] `dateToIsoDate()` replaces inline date coercion in `findOverlapWarnings`
- [ ] Projection corpus byte-identical

### Phase aw-1 — Terminology: Care team to Veterinary team

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw1-terminology-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/l10n/**
flutter_app/lib/features/vet/**
flutter_app/lib/features/experience/**
flutter_app/lib/core/widgets/collection_filter/**
flutter_app/test/**
flutter_app/test/bdd/features/guardian_dashboard.feature
e2e/playwright/pages/**
e2e/playwright/support/flutter.ts
docs/design/terminology.md
```

**Exit criteria:**

- [ ] EN "Veterinary team" / FR "Équipe vétérinaire" on all vet surfaces
- [ ] Personal-scope filter chip uses its own key, not `myVets`
- [ ] Terminology doc records the split; "care team" reserved for carers
- [ ] BDD + Playwright locators updated in the same PR

### Phase aw-2 — Routing restructure

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw2-routing-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/core/router/**
flutter_app/lib/features/pet_care/context/presentation/screens/**
flutter_app/lib/features/pet_care/context/presentation/widgets/planned_absence_entry_tile.dart
flutter_app/test/core/router/**
```

**Exit criteria:**

- [ ] `/pc/away` (hub), `/pc/away/new` (wizard), `/pc/away/:id` (plan page) registered
- [ ] All three named routes covered in `guardian_routes_test.dart`
- [ ] Wizard save navigates to the plan page instead of `context.pop()`

### Phase aw-3 — Projection read contract

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw3-projection-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/lib/care/schedule/projectSchedule.js
server/lib/care/awayPlan/**
server/routes/careContext/**
server/test/careContext/**
server/test/careSchedule/**
```

**Exit criteria:**

- [ ] `uncertainties[]` carries `name`, `type`, `care_family`
- [ ] Server-side routine/dated split; collapsed rows take minimum constituent certainty
- [ ] `items[]` byte-identical against the existing corpus

### Phase aw-4 — Carer schema and CRUD

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw4-carer-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
db/migrations/**
db/schema/**
server/routes/careContext/**
server/lib/care/plannedAbsence.js
server/test/careContext/**
server/test/migrations/**
docs/architecture/api-reference.md
```

**Exit criteria:**

- [ ] Migration `063` up/down; manifest + canonical regenerated; equivalence gate green
- [ ] `shared_user` requires `pet_access` on that pet; `403` otherwise
- [ ] `note_only` grants nothing — no `pet_access`, share link or notification
- [ ] Carer writes share the absence write transaction and bump `updated_at`

### Phase aw-5 — Hub content

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw5-hub-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/routes/careContext/**
server/test/careContext/**
flutter_app/lib/features/pet_care/context/**
flutter_app/test/features/pet_care/context/**
```

**Exit criteria:**

- [ ] Additive `scope` parameter (`upcoming` default, `past`, `all`) — past absences are unreachable today
- [ ] `plannedAbsencesListProvider` watched, not only invalidated
- [ ] Upcoming ascending, past subdued descending, cancelled hidden

### Phase aw-6 — Stateful dashboard tile

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw6-tile-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_care/context/presentation/widgets/**
flutter_app/lib/features/experience/presentation/widgets/pet_care_shell_home_content.dart
flutter_app/test/features/pet_care/context/**
flutter_app/test/features/experience/**
```

**Exit criteria:**

- [ ] Three states render from the list provider; loading/error degrade to the plain prompt
- [ ] Always routes to the hub, never the wizard
- [ ] No percentage or checklist mechanic

### Phase aw-7 — Plan page

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw7-plan-page-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_care/context/**
flutter_app/test/features/pet_care/context/**
```

**Exit criteria:**

- [ ] Collapsed routine rows render the least-certain constituent state
- [ ] Indeterminate entries render as named rows, not omissions
- [ ] `shared_user` vs `note_only` visually distinct; no implied access
- [ ] No reschedule affordance, not even disabled
- [ ] Files under 500 lines

### Phase aw-8 — Readiness derivation

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw8-readiness-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/lib/care/awayPlan/**
server/routes/careContext/**
server/test/careContext/**
flutter_app/lib/features/pet_care/context/**
flutter_app/test/features/pet_care/context/**
```

**Exit criteria:**

- [ ] 15-case matrix: (carer set / partial / unset) × five coverage states
- [ ] `nothing_scheduled` never claims coverage
- [ ] No persisted readiness column; asserted
- [ ] Tile, plan page and handover share one derivation

### Phase aw-9 — Handover document

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw9-handover-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/pet_care/context/**
flutter_app/test/features/pet_care/context/**
server/routes/careContext/**
server/test/careContext/**
db/migrations/**
db/schema/**
```

**Exit criteria:**

- [ ] Client-side PDF via existing `pdf` / `printing` packages; no server PDF dependency
- [ ] Indeterminate items present in the document
- [ ] Handover note verbatim; test asserts no CIM or pet-facts path
- [ ] "Changed since download" notice with copy matching the D-AWAY-009 scope

### Phase aw-seed — Away planning seed scenario (parallel after aw-4)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw-seed-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/db/seeds/**
server/scripts/seed.js
server/test/seed.test.js
docs/e2e/uat-demo-data.md
```

**Exit criteria:**

- [ ] `away-planning.js` registered in `SCENARIOS` **and** `ALL_SCENARIOS`, ordered after `care-schedule-fixture`
- [ ] `seed.test.js` asserts both registrations
- [ ] Idempotent across two consecutive runs
- [ ] Covers all five coverage states, carer mix, past/upcoming/cancelled, downloaded-then-edited

### Phase aw-10 — Canonical docs and journey coverage

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw10-docs-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
docs/domains/pet_care/**
docs/architecture/api-reference.md
docs/design/terminology.md
flutter_app/test/bdd/features/**
e2e/playwright/**
```

**Exit criteria:**

- [ ] `care-context.md` canonical for hub / plan page / carer model; preview-only framing removed
- [ ] Carer model semantics and the Pet Sitting boundary documented
- [ ] CC-4 "pull-only; no dashboard slot" marked superseded
- [ ] `away_planning.feature` + Playwright spec with exact-matching `@bdd` header
