---
title: Care date screen v4 (four blocks)
owner: Agent
audience: agent
status: active
last_updated: 2026-10-14
tags: [pet_care, care_item, ui, execute-plan]
---

# care-date-blocks-v4-e8f1

## Goal

Deliver Care date **v4**: four blocks (context → schedule/absence → completion → chronological neighbours), neighbours on `GET …/occurrences/:occId`, **Option (a)** completion **date only** on wire, inline date on leaf (DN-3 sheet bypass on leaf only), superseding b20d layout decisions.

**One verifiable outcome:** Care date matches CARE-ITEM-R-016 … R-020; docs and BDD/E2E guard regressions; integration → `main` via `/babysit-uat`.

**Integration:** Five phase PRs → `cursor/care-date-blocks-v4-e8f1-integration-e8f1`, then one PR → `main`.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-date-blocks-v4-e8f1` |
| **created** | 2026-10-14 |
| **base_branch** | `cursor/care-date-blocks-v4-e8f1-integration-e8f1` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **orchestration** | **continuous** — one grant through release |
| **approved_until** | Extended for full programme (see snapshot) |

## Continuous execute-plan contract

Owner intent (2026-10-14): **no stops between phases**; full autonomy until **`complete-plan`** after integration → `main`.

| Rule | Behaviour |
|------|-----------|
| **Integration trunk** | All phase PRs target `cursor/care-date-blocks-v4-e8f1-integration-e8f1` only. |
| **Phase loop** | After phase *N* merges: immediately start phase *N+1* (gate `0`, same control issue) — **not** a user-visible stop. |
| **Babysit** | `/babysit-plus` every phase PR; **`/babysit-uat` only** on the **release PR** integration → `main`. |
| **User chat** | Blockers / escalation / `complete-plan` summary only (AGENTS.md §Execute-plan). |
| **Waves** | One wave: phases **1 → 2 → 3 → 4 → 5** on integration, then **release** integration → `main`. No parallel phase agents unless `spawn_allowed` is set (false). |
| **Expiry** | `approved_until` must cover all phases + release; re-approve only on halt/expiry. |

**Release (post-phase 5):** Open PR `cursor/care-date-blocks-v4-e8f1-integration-e8f1` → `main`; drive `/babysit-uat`; then `complete-plan care-date-blocks-v4-e8f1`.

## Canonical docs

| Path | When |
|------|------|
| `docs/domains/pet_care/features/care-item-evolution.md` | Planned rows at bootstrap; **rewrite** § Care date in place per phase; R-016–020 → Live in phase 5 |
| `docs/design/care-item-view-ui.md` | Phases 2–5 as modules ship |
| `docs/architecture/api-reference.md` | Phase 1 neighbour DTO |
| `docs/domains/pet_care/changes/care-date-blocks-v4-spec.md` | Delete phase 5 |

## Router

| Field | Value |
|-------|-------|
| **router_risk** | R2 phase 1 API; R1 phases 2–4 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing`, `documentation`, `api-contract` (phase 1) |
| **verification** | `check_file_size.js`, `flutter analyze`, `pre-push-changed.sh`, Jest neighbours, widget + E2E per phase |

## Supersedes (document in decision log)

| ID | Superseded by |
|----|----------------|
| D-OSM-002 | CARE-ITEM-D-002 (pet avatar tappable) |
| D-OSM-003 | CARE-ITEM-D-003 (no recurring icon on leaf) |
| D-OSM-006, D-OSM-010 | CARE-ITEM-D-004 (chronological neighbours) |
| D-OSM-013 … D-OSM-016 | CARE-ITEM-D-001 (four-block layout) |
| D-OCC-011 (Reopen copy) | CARE-ITEM-D-005 |
| D-CIE-037 (DN-3 on leaf) | CARE-ITEM-D-006 |

## New decisions (Planned → Live)

| ID | Summary |
|----|---------|
| CARE-ITEM-D-001 | Four blocks 1→2→3→4 on phone and wide |
| CARE-ITEM-D-002 | Pet avatar on Block 1 navigates to pet profile |
| CARE-ITEM-D-003 | No recurring/planned icon on Care date leaf |
| CARE-ITEM-D-004 | Previous/next chronological stored occurrences; empty copy when none |
| CARE-ITEM-D-005 | **Reopen** = undo when `canUndoHere`; completion-date change keeps `careUndoDateChange` |
| CARE-ITEM-D-006 | Leaf completion uses inline date; DN-3 sheet only off-leaf |
| CARE-ITEM-D-007 | Default completion date `min(due_date, as_of.date)`; scheduled time read-only (R-021 deferred) |

## Completion matrix (Care date leaf)

| Case | Behaviour |
|------|-----------|
| Fixed, on time | `completed_on` = as_of.date or user-picked date |
| Fixed, overdue | User date; DN-5 offer change date unchanged |
| After-it's-done, overdue | Inline date (no sheet); explicit test for `completed_on` sent |
| Coming up (future due) | Default `as_of.date` not due date |
| DN-4 early | Confirm dialog unchanged |
| PL-5 earlier open | `DoneOpensCareItem` unchanged |
| Off-leaf DN-3 | Sheet still shown |

## Sanity check

**Result:** `proceed` — five phases, one API addition, integration branch.

## Autonomy

Owner approved Option (a) and `/execute-plan` in chat 2026-10-14.

---

## Phase 1 — Neighbours API + wire models

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-date-blocks-v4-api-e8f1` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
server/lib/health/occurrenceNeighbors.js
server/lib/health/**
server/routes/healthEntries/occurrencePatchRouter.js
server/test/db/careOccurrences.neighbors.integration.test.js
server/test/health/**
flutter_app/lib/features/care_item/domain/occurrence_neighbor.dart
flutter_app/lib/features/care_item/data/care_item_wire.dart
flutter_app/lib/features/care_item/domain/occurrence_detail.dart
flutter_app/test/features/care_item/data/care_item_wire_occurrence_detail_test.dart
docs/architecture/api-reference.md
docs/domains/pet_care/features/care-item-evolution.md
docs/domains/pet_care/changes/care-date-blocks-v4-spec.md
.agents/plans/care-date-blocks-v4-e8f1.*
```

**forbidden_paths:** `e2e/**`, `db/migrations/**`, `flutter_app/lib/features/experience/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:** `previous_occurrence` / `next_occurrence` on occurrence GET; sort `scheduled_date`, `scheduled_time` nulls first, tie `id`; `occurrence_status` via `occurrenceStatusFor`; Jest integration tests; Flutter parse; api-reference; flip R-020 doc to In delivery in canonical.

**Exit criteria:**

- [ ] Neighbour DTO on GET; authz + same-entry tests green
- [ ] Flutter wire tests
- [ ] `pre-push-changed.sh` green

---

## Phase 2 — Blocks 1 & 2

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-date-blocks-v4-context-e8f1` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/features/care_item/domain/occurrence_detail.dart
flutter_app/lib/features/care_item/data/care_item_wire.dart
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/presentation/**
flutter_app/test/features/experience/presentation/care_item/occurrence/**
e2e/playwright/pages/occurrence.page.ts
e2e/playwright/pages/away-planning.page.ts
e2e/playwright/tests/care.agenda.spec.ts
docs/design/care-item-view-ui.md
docs/domains/pet_care/features/care-item-evolution.md
.agents/plans/care-date-blocks-v4-e8f1.*
```

**forbidden_paths:** `server/**`, `db/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:** `OccurrenceCareContextCard`, `OccurrenceScheduleSection`; remove schedule from identity / remove standalone Away module; icon reschedule + `CareSkipButton`; carer read-only; absence in Block 2 + green plane token; Reopen in Block 2; retire `occurrence_open_care_details` in same PR with page object updates.

**Exit criteria:**

- [ ] B1/B2 widget tests incl. 320dp text scale 2.0
- [ ] E2E locators for touched specs green locally
- [ ] FR l10n

---

## Phase 3 — Block 3 completion

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-date-blocks-v4-complete-e8f1` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/care_item/domain/done_decision.dart
flutter_app/lib/features/care_item/presentation/care_completion_flow.dart
flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_complete_care_module.dart
flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_open_actions.dart
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/domain/done_decision_test.dart
flutter_app/test/features/care_item/presentation/**
flutter_app/test/features/experience/presentation/care_item/occurrence/**
e2e/playwright/tests/weight.care.spec.ts
docs/domains/pet_care/features/care-item-evolution.md
.agents/plans/care-date-blocks-v4-e8f1.*
```

**forbidden_paths:** `server/**`, `db/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:** Inline completion date; read-only scheduled time; `CareMarkDoneButton`; bypass DN-3 when `onOccurrenceScreen` + `completedOn`; completion matrix tests; sheet still off-leaf.

**Exit criteria:**

- [ ] Matrix tests pass
- [ ] `pre-push-changed.sh` green

---

## Phase 4 — Block 4 navigation

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/care-date-blocks-v4-nav-e8f1` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/core/router/shell_return_navigation.dart
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/presentation/**
flutter_app/test/features/experience/presentation/care_item/occurrence/**
e2e/playwright/pages/occurrence.page.ts
e2e/playwright/tests/care.item.booster.spec.ts
docs/design/care-item-view-ui.md
docs/domains/pet_care/features/care-item-evolution.md
.agents/plans/care-date-blocks-v4-e8f1.*
```

**forbidden_paths:** `server/**`, `db/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:** Remove `OccurrenceNextOpenModule`; neighbour cards; `go` replace for `<`/`>`; stack cards vertically when width <360 or text scale ≥1.3; analytics `occurrence_neighbor_opened`.

**Exit criteria:**

- [ ] Neighbour navigation widget tests
- [ ] Retire `occurrence_next_open` locators in same PR

---

## Phase 5 — BDD, canonical Live, release

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/care-date-blocks-v4-verify-e8f1` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/test/bdd/features/care_date_screen.feature
e2e/playwright/tests/care.date.spec.ts
e2e/playwright/pages/**
e2e/playwright/tests/care.agenda.spec.ts
e2e/playwright/tests/weight.care.spec.ts
flutter_app/test/features/care_item/**
docs/domains/pet_care/features/care-item-evolution.md
docs/design/care-item-view-ui.md
docs/domains/pet_care/changes/care-date-blocks-v4-spec.md
.agents/plans/care-date-blocks-v4-e8f1.*
```

**forbidden_paths:** `server/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:** `care_date_screen.feature` + `@bdd` Playwright; Given/When/Then AC rows Live; delete change doc; plan `autonomy: completed`; integration → main PR.

**Exit criteria:**

- [ ] `check_bdd_coverage.js` green
- [ ] R-016–020 Live; CARE-ITEM-D-001–007 Live
- [ ] Pre-UAT path ready on integration

## Runtime state

```yaml
autonomy: active
current_phase: 5
last_completed_phase: 4
halt_reason: null
next_action: "continue phase 5 on branch cursor/care-date-blocks-v4-verify-e8f1"
artifact_ref:
  branch: cursor/care-date-blocks-v4-verify-e8f1
  plan_path: .agents/plans/care-date-blocks-v4-e8f1.md
  plan_commit: 2c0dcfc820abf133e06064936e9da4de55f840be
  snapshot_path: .agents/plans/care-date-blocks-v4-e8f1.snapshot.json
  snapshot_commit: 2c0dcfc820abf133e06064936e9da4de55f840be
open_prs: []
merge_commits: {}
debt_issue_refs: []
```
