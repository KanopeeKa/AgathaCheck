---
title: Away Planning V1
plan_id: away-planning-v1
---

# Away Planning V1

| Field | Value |
|-------|-------|
| **plan_id** | `away-planning-v1` |
| **title** | Away Planning V1 (AW-EMERGENCY through AW-10) |
| **base_branch** | `cursor/away-planning-v1-integration-5176` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Evolve `care_context` into Away Planning: hub, plan page, per-pet carer model, derived readiness (two facts), printable handover. Scheduling stays with CSM.

**Canonical docs:** `docs/domains/pet_care/changes/away-planning-delivery-plan.md`
**Frozen decisions:** `docs/domains/pet_care/changes/away-planning-decisions.md` (confirmed 2026-09-15)

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-15T19:24:54Z |
| **approved_until** | 2026-09-17T19:24:54Z |
| **approved_by** | User chat 2026-09-15 — confirmed plan review #1196; proceed autonomously with `/execute-plan` |
| **autonomy** | `active` |
| **control_issue** | [#1198](https://github.com/KanopeeKa/AgathaCheck/issues/1198) |

## Phases

**AW-EMERGENCY** targets `main` directly. All other phases target the integration branch unless noted.

AW-DOC-0, AW-0, AW-1, AW-2, AW-3 parallel. AW-5a parallel with AW-4 after AW-0. AW-8 before AW-6. AW-2 additive until AW-5b flips `/pc/away`.

### Phase aw-emergency — Hang-on-error fix (main)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-emergency-5176` |
| **base** | `main` |
| **spawn_allowed** | `false` |

**allowed_paths:** `server/routes/careContext/carePeriodCoverageRouter.js`, `server/routes/careContext/carePeriodProjectionRouter.js`, `server/test/careContext/carePeriodCoverageApi.test.js`, `server/test/careContext/carePeriodProjectionApi.test.js`

**Exit criteria:**

- [ ] Both routers return `500` JSON on DB failure (not hang)
- [ ] Regression tests with explicit timeout
- [ ] Repo-wide `publicError(res` grep = 0

### Phase aw-doc-0 — Plan bootstrap

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-v1-plan-5176` |
| **spawn_allowed** | `false` |

**allowed_paths:** `docs/**`, `.agents/plans/away-planning-v1.md`

**Exit criteria:**

- [ ] D-AWAY-001–013 Frozen
- [ ] Delivery plan + execute-plan updated
- [ ] `explainGap` contract in care-context.md; CC-4 superseded; terminology updated

### Phase aw-0 — Backend hygiene

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw0-5176` |

**allowed_paths:** `server/routes/careContext/plannedAbsencesRouter.js`, `server/lib/care/plannedAbsence.js`, `server/lib/calendarDate.js`, `server/lib/db/**`, `server/test/careContext/**`, `server/test/pets/helpers.js`

**Exit criteria:** transactions, batch pet ids, bulk insert, `dateToIsoDate`, tx mock, `timestampToIso` in careContext only, corpus byte-identical

### Phase aw-1 — Terminology

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw1-terminology-5176` |

**allowed_paths:** `flutter_app/lib/l10n/**`, `flutter_app/lib/features/vet/**`, `flutter_app/lib/features/experience/**`, `flutter_app/lib/core/widgets/collection_filter/**`, `flutter_app/test/**`, `flutter_app/test/bdd/features/guardian_dashboard.feature`, `e2e/playwright/**`, `docs/design/terminology.md`, `docs/domains/pet_profile/**`

### Phase aw-2 — Routing (additive)

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw2-routing-5176` |

**allowed_paths:** `flutter_app/lib/core/router/**`, `flutter_app/lib/features/pet_care/context/**`, `flutter_app/test/core/router/**`

### Phase aw-3 — Projection read contract

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw3-projection-5176` |

**allowed_paths:** `server/lib/care/schedule/projectSchedule.js`, `server/lib/care/awayPlan/**`, `server/routes/careContext/carePeriod*`, `server/test/careContext/**`, `server/test/careSchedule/**`

### Phase aw-4 — Carer schema + API

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw4-carer-5176` |

**allowed_paths:** `db/migrations/**`, `db/schema/**`, `server/routes/careContext/**`, `server/routes/pets/**`, `server/lib/care/plannedAbsence.js`, `server/test/careContext/**`, `server/test/migrations/**`, `docs/architecture/api-reference.md`

### Phase aw-5a — List API

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw5a-list-api-5176` |

**allowed_paths:** `server/routes/careContext/plannedAbsencesRouter.js`, `server/test/careContext/plannedAbsences.test.js`

### Phase aw-8 — Readiness derivation

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw8-readiness-5176` |

**allowed_paths:** `server/lib/care/awayPlan/**`, `server/routes/careContext/**`, `server/test/careContext/**`

### Phase aw-5b — Hub UI

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw5b-hub-5176` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/**`, `flutter_app/lib/core/router/**`, `flutter_app/test/features/pet_care/context/**`

### Phase aw-6 — Stateful tile

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw6-tile-5176` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/**`, `flutter_app/lib/features/experience/**`, `flutter_app/test/**`, `docs/domains/pet_profile/**`

### Phase aw-7 — Plan page

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw7-plan-page-5176` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/**`, `flutter_app/test/features/pet_care/context/**`

### Phase aw-9 — Handover document

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw9-handover-5176` |

**allowed_paths:** `flutter_app/lib/features/pet_care/context/**`, `server/routes/careContext/**`, `db/migrations/**`, `db/schema/**`, `server/test/careContext/**`

### Phase aw-seed — Seed scenario

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw-seed-5176` |

**allowed_paths:** `server/db/seeds/**`, `server/scripts/seed.js`, `server/test/seed.test.js`, `docs/e2e/uat-demo-data.md`

### Phase aw-10 — Docs + journey

| Field | Value |
|-------|-------|
| **branch** | `cursor/away-planning-aw10-docs-5176` |

**allowed_paths:** `docs/domains/pet_care/**`, `docs/architecture/api-reference.md`, `flutter_app/test/bdd/**`, `e2e/playwright/**`

## Runtime state

```yaml
autonomy: active
current_phase: aw-0
last_completed_phase: aw-3
halt_reason: null
next_action: "continue phase aw-0 on branch cursor/away-planning-aw0-5176"
artifact_ref:
  branch: cursor/away-planning-v1-integration-5176
  plan_path: .agents/plans/away-planning-v1.md
  plan_commit: 5053f9c77dd7c0522121230b72268d96947fcbed
  snapshot_path: .agents/plans/away-planning-v1.snapshot.json
  snapshot_commit: 5053f9c77dd7c0522121230b72268d96947fcbed
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1201"]
merge_commits: {"aw-emergency":"48082deb88660705c32c93a22c22ebb0e73e350b"}
debt_issue_refs: []
```
