---
title: Care date screen module layout (v2)
owner: Agent
audience: agent
status: active
last_updated: 2026-10-08
tags: [pet_care, care_item, ui, execute-plan]
---

# occurrence-screen-modules-5ec0

## Goal

Evolve the **Care date** leaf screen (`OccurrenceScreen`) from v1 flat sections to the **module-based occurrence layout** agreed in chat (2026-10-08) and captured in [`docs/domains/pet_care/changes/occurrence-screen-modules-spec.md`](../../docs/domains/pet_care/changes/occurrence-screen-modules-spec.md).

**Outcome:** Users see **one occurrence of a known Care** — identity card → complete care → optional away → next open date — with the same care surface tokens as Care Item detail, on phone and web.

**Integration:** Three phase PRs merge to `cursor/occurrence-screen-modules-5ec0-integration-5ec0`, then **one** PR integration → `main` with `/babysit-uat`.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `occurrence-screen-modules-5ec0` |
| **title** | Care date screen — module layout v2 |
| **created** | 2026-10-08 |
| **base_branch** | `cursor/occurrence-screen-modules-5ec0-integration-5ec0` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Canonical docs

| Path | Phase |
|------|-------|
| `docs/domains/pet_care/changes/occurrence-screen-modules-spec.md` | 1 (author); fold + delete in 3 |
| `docs/domains/pet_care/features/care-item-evolution.md` § Care date screen | 3 (Mode A sync, D-OSM-* decision log) |

## Router (strengthen)

| Field | Value |
|-------|-------|
| **router_risk** | R1 (Flutter UI + l10n; no API) |
| **protocols** | `accessibility`, `flutter-mobile`, `testing`, `documentation` |
| **verification** | `node scripts/check_file_size.js`, `flutter analyze`, `./scripts/pre-push-changed.sh`, widget tests, E2E page object smoke |
| **phase_fit** | in-scope |

## Sanity check

**Result:** `proceed`

- No server/schema/auth changes.
- Bounded to occurrence presentation + tests + docs.
- Three phases keep PRs reviewable; integration branch batches merge to `main` once.

**Not in scope (debt if requested later):**

- Extracting a global `ObjectCard` primitive for non-occurrence screens.
- Changing Care Item context strip to match identity card.
- BDD scenario rewrites unless a tagged journey breaks.

## Autonomy (before grant)

| Step | Action |
|------|--------|
| 1 | Review this plan + changes spec |
| 2 | `node scripts/validate_execute_plan_snapshot.js .agents/plans/occurrence-screen-modules-5ec0.snapshot.json --fix-hash` |
| 3 | `node scripts/execute_plan_runtime.js init-control-issue occurrence-screen-modules-5ec0` → create issue, set `control_issue` in snapshot |
| 4 | Create integration branch from `main`: `cursor/occurrence-screen-modules-5ec0-integration-5ec0` |
| 5 | Comment **`approve-autonomous occurrence-screen-modules-5ec0`** on control issue; set `autonomy: active`, `approved_at` / `approved_until` (+48h), `approved_by`, freeze `content_hash` |
| 6 | `/execute-plan occurrence-screen-modules-5ec0` |

**Grant keyword:** `approve-autonomous occurrence-screen-modules-5ec0`

---

## Phase 1 — Shell, canvas, and identity card

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/occurrence-screen-modules-identity-5ec0` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
docs/domains/pet_care/changes/occurrence-screen-modules-spec.md
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/features/care_item/domain/next_open_occurrence.dart
flutter_app/lib/l10n/**
.agents/plans/occurrence-screen-modules-5ec0.*
```

**forbidden_paths:** `server/**`, `.github/workflows/**`, `db/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Finalize changes spec if gaps found during implementation.
- Add pure helper `next_open_occurrence.dart`: given current `CareOccurrence` + `CareItemSchedule`, return next open occurrence id/date/time or null (sort by scheduled date, then id).
- New `OccurrenceIdentityCard`:
  - Left: family icon + label + schedule affordance (D-OSM-003); tap → Care details.
  - Right: care name, datetime line, inline status pill + `occurrenceDaysOverdue` when overdue (new ARB).
  - Pet chip below (D-OSM-004); optional **View all dates** text button.
- `OccurrenceScreen`:
  - Wrap body in `CareItemDetailCanvas`.
  - Route through `ExperienceShellScaffold` (mirror Care Item detail pattern for Pet Care).
  - Replace `OccurrenceContextTile`, `OccurrenceTitleRow`, `OccurrenceStatusSection` with identity card only.
  - Keep `OccurrenceAbsenceSection` and `OccurrenceBlocks` temporarily below identity (unchanged behaviour) to land shell + header in one reviewable slice.
- l10n EN + FR for datetime/overdue/identity strings introduced in this phase.
- Semantics: `occurrence_identity_card`, preserve `occurrence_screen`; care-type link `occurrence_open_care_details` (new) replacing `occurrence_about_item` intent.

**Exit criteria:**

- [ ] Care date screen shows module identity card on warm canvas with experience shell.
- [ ] No labeled **Status** section; status visible inline on identity card.
- [ ] App bar title remains **Care date**; no overflow menu.
- [ ] `next_open_occurrence` unit tests (domain) for sort edge cases.
- [ ] `./scripts/pre-push-changed.sh` green on touched paths.

---

## Phase 2 — Complete care module and next open navigation

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/occurrence-screen-modules-actions-5ec0` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/features/care_item/domain/next_open_occurrence.dart
flutter_app/lib/l10n/**
.agents/plans/occurrence-screen-modules-5ec0.*
```

**forbidden_paths:** `server/**`, `.github/workflows/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- New `OccurrenceCompleteCareModule` (`CareItemModule` wrapper):
  - Header copy (D-OSM-009).
  - Refactor `OccurrenceBlocks` into module (split file if >500 lines).
  - Move **Reschedule** from deleted title row into secondary row with Skip (D-OSM-005); single `rescheduleOccurrenceDate` entry point.
  - Rename completion field label to **Completion date** (ARB).
- New `OccurrenceNextOpenModule`:
  - Uses `next_open_occurrence` helper (D-OSM-006).
  - Navigate via `openOccurrenceScreen`.
  - Wide layout: row with Complete care (flex 3) + Next open (flex 2) below identity.
- Remove dead widgets: `occurrence_context_tile.dart`, `occurrence_title_row.dart`, `occurrence_status_section.dart` (or thin re-exports deleted).
- Away section remains between complete and next modules.

**Exit criteria:**

- [ ] Open occurrence: Reschedule only in Complete care module; no header reschedule.
- [ ] Next open module hidden when no successor; visible with correct date when second open exists.
- [ ] Done / skipped / closed-not-recorded layouts still functional inside module.
- [ ] All hand-written files ≤500 lines.
- [ ] `./scripts/pre-push-changed.sh` green.

---

## Phase 3 — Tests, E2E, canonical sync

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/occurrence-screen-modules-verify-5ec0` |
| **exit_checklist** | `default` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
docs/domains/pet_care/features/care-item-evolution.md
docs/domains/pet_care/changes/occurrence-screen-modules-spec.md
flutter_app/test/features/care_item/**
flutter_app/test/features/experience/**
e2e/playwright/pages/occurrence.page.ts
e2e/playwright/pages/care-item.page.ts
.agents/plans/occurrence-screen-modules-5ec0.*
```

**forbidden_paths:** `server/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- Update `occurrence_screen_test.dart`, `occurrence_status_section_test.dart` (remove or repurpose), add identity + next-open widget tests.
- Semantics contract tests for new identifiers.
- `OccurrencePage`: `expectLoaded` accepts identity card; `openCareDetails` via new semantics; optional `goToNextOpen`.
- **Canonical-docs Mode A:** Update `care-item-evolution.md` § Care date screen layout + decision log D-OSM-001 … D-OSM-010; amend D-OCC-005 layout table.
- Delete `occurrence-screen-modules-spec.md` when fully delivered.
- Plan `complete-plan` after integration → `main` PR merges.

**Exit criteria:**

- [ ] Widget tests cover identity card, complete module, next-open visibility.
- [ ] E2E locators updated; existing guardian/agenda paths that open Care date still pass smoke assumptions.
- [ ] Canonical doc synced; changes doc removed.
- [ ] Integration branch PR to `main` opened; `/babysit-uat` pre-UAT green on merge commit.

---

## Final merge to main

After phases 1–3 merged into integration:

1. `./scripts/pre-push.sh` on integration branch tip.
2. PR: `cursor/occurrence-screen-modules-5ec0-integration-5ec0` → `main`.
3. `/babysit-uat` on that PR.

## Analytics (unchanged unless noted)

Keep: `occurrence_screen_opened`, `care_completion_date_changed`.

Optional (phase 2): `occurrence_next_open_tapped` — only if product wants funnel data; otherwise skip.

## Runtime state (agent-updated)

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: awaiting approve-autonomous
next_action: init-control-issue → approve-autonomous → phase 1
artifact_ref:
  branch: null
  plan_path: .agents/plans/occurrence-screen-modules-5ec0.md
  snapshot_path: .agents/plans/occurrence-screen-modules-5ec0.snapshot.json
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Checklist before `approve-autonomous`

- [ ] Human sign-off on changes spec (D-OSM decisions)
- [ ] Snapshot validates
- [ ] Control issue created with labels `execute-plan`, `plan:occurrence-screen-modules-5ec0`, `autonomous-approved`
- [ ] Integration branch pushed to origin
