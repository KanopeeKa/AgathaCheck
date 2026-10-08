---
title: Care date screen evolution (identity + actions IA)
owner: Agent
audience: agent
status: active
last_updated: 2026-10-08
tags: [pet_care, care_item, ui, execute-plan]
---

# care-date-evolution-b20d

## Goal

Evolve the **Care date** leaf screen so users orient on **pet + care family**, mutate the **scheduled slot** (change date / skip) next to **when**, see **Away** before committing, and complete with a **single primary** Mark as done — without losing overdue / backdated completion behaviour.

**One verifiable outcome:** Care date module order and actions match signed-off IA; completion-date behaviour remains correct after removing the inline picker; canonical docs record D-CIE-037 / D-OSM-013+.

**Integration:** Three phase PRs → `cursor/care-date-evolution-b20d-integration-b20d`, then one PR → `main` (`/babysit-uat`).

**Product sign-off (2026-10-08 chat):** agreed recommendations; ideas **2** (shared schedule action bar), **3** (legacy dates-section debt), **4** (no icon header on Complete module); canonical doc updates and listed risks accepted.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-date-evolution-b20d` |
| **created** | 2026-10-08 |
| **base_branch** | `cursor/care-date-evolution-b20d-integration-b20d` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Canonical docs

| Path | When |
|------|------|
| `docs/domains/pet_care/features/care-item-evolution.md` | § Care date screen — fold phase 3 |
| `docs/design/care-item-view-ui.md` | One paragraph on leaf vs Care item shortcuts (phase 3) |

**Proposal (phase 1 only):** `docs/domains/pet_care/changes/care-date-evolution-spec.md` (`status: proposed`) — delete after canonical fold in phase 3.

**Docs gate per PR:**

- Phase 1–2: `Docs: N/A — spec in changes/care-date-evolution-spec.md; canonical fold phase 3` (unless phase touches copy-only l10n without behaviour — still N/A until fold).
- Phase 3: full `/canonical-docs` sync (Mode A).

## Router (strengthen at phase start)

| Field | Value |
|-------|-------|
| **router_risk** | R1 (phase 1–2 UI + domain flow); R1 phase 3 docs/E2E |
| **protocols** | `accessibility`, `flutter-mobile`, `testing`, `documentation` |
| **verification** | `check_file_size.js`, `flutter analyze`, `pre-push-changed.sh`, widget tests, E2E locator updates (phase 3) |

## Signed-off design (summary)

### Identity (`OccurrenceIdentityCard`)

- **Left rail:** large `CareFamilyIcon` (`showChip: true`, `chipSize` 48–56) → recurring/planned icon (24px) → pet avatar (48) → pet name **regular weight** (not bold); pet tap → pet detail.
- **Right:** care name (calmer than today — avoid competing with primary CTA), scheduled datetime, status pill + overdue helper, **`OccurrenceScheduleActionBar`** (open only), **View care details**.
- Remove horizontal `CareItemPetContextTile` from right column (replace with vertical rail widget).

### `OccurrenceScheduleActionBar` (idea 2)

- Shared widget under `occurrence/` (or `care_item/widgets/` if reused later).
- Row: two `Expanded(OutlinedButton.icon)` — **Change date** (`rescheduleActionLabel`, `Icons.edit_calendar_outlined`) + **Skip** (`careSkip`, `Icons.skip_next`); `minHeight` 48; keys `occurrence_reschedule`, `occurrence_skip`; semantics identifiers unchanged.
- Hidden when occurrence not open; Change date hidden when `!occurrenceShowsReschedule`.

### Module order (`OccurrenceScreenBody`)

Phone and wide: **Identity → Away (if visible) → Complete → Next open**.

### Complete module (`OccurrenceCompleteCareModule`)

- Remove **This date** header, check icon, and open-state completion-date `ListTile` (idea 4).
- Open state: weight field (if required) + full-width **Mark as done** only.
- Done/skipped/closed: unchanged controls in `OccurrenceClosedActions`.

### Functional model (docs only in phase 3)

- **Care date** = canonical UI leaf for one occurrence; APIs already per `occurrenceId`.
- **Care item** rows / bulk = shortcuts; **Mark all** = N occurrence commands, not a separate “confirm care” concept.

## Risks (accepted — implement mitigations)

| ID | Risk | Mitigation (owner phase) |
|----|------|-------------------------|
| R1 | Removing inline completion date breaks DN-3 (`decideDone` skips `DoneAsksDate` when `onOccurrenceScreen`) | Phase 2: stop skipping DN-3 on occurrence screen **or** route Mark as done through `showCompletionDateSheet` when overdue after-done; widget tests for overdue open + after-done |
| R2 | Users lose obvious backdate without picker | Phase 2: rely on DN-3 sheet; optional follow-up debt for tertiary “Done on another day” (not in scope unless trivial in phase 2) |
| R3 | Schedule actions in identity card blur read vs act | Outlined secondary only; filled CTA stays in Complete module |
| R4 | E2E / widget order assumptions (Away before Complete) | Phase 3: update `occurrence.page.ts`, `occurrence_screen_test.dart` scroll order |
| R5 | Copy drift “Reschedule” vs “Change date” | Phase 1: use `rescheduleActionLabel` on Care date actions |
| R6 | Legacy duplicate controls in `care_item_dates_section.dart` | Phase 3: **debt issue** only (idea 3) — do not refactor dates section in this plan |

## Sanity check

**Result (pre-grant):** `proceed` — three phases, Flutter-only, no API/DB; integration branch required.

## Autonomy (before grant)

**Control issue:** [#1807](https://github.com/KanopeeKa/AgathaCheck/issues/1807)

1. Review this plan + `changes/care-date-evolution-spec.md` (created in phase 1 PR or bootstrap commit).
2. `node scripts/validate_execute_plan_snapshot.js .agents/plans/care-date-evolution-b20d.snapshot.json --fix-hash`
3. `git push -u origin cursor/care-date-evolution-b20d-integration-b20d`
4. `node scripts/execute_plan_runtime.js init-control-issue care-date-evolution-b20d` → create issue; set `control_issue` in snapshot; re-validate hash.
5. Comment on control issue: `approve-autonomous care-date-evolution-b20d` (reference chat sign-off 2026-10-08).
6. Set snapshot `autonomy: active`, `approved_at`, `approved_until` (+48h), `approved_by`; `--fix-hash`; commit on integration branch.
7. `/execute-plan care-date-evolution-b20d`

---

## Phase 1 — Layout, identity rail, schedule action bar

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-date-evolution-ui-b20d` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/pet_care/changes/care-date-evolution-spec.md
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/presentation/occurrence_*.dart
flutter_app/test/features/experience/presentation/care_item/occurrence/**
.agents/plans/care-date-evolution-b20d.*
```

**forbidden_paths:** `server/**`, `.github/workflows/**`, `db/**`, `e2e/**`, `flutter_app/lib/features/care_item/domain/done_decision.dart`, `flutter_app/lib/features/care_item/presentation/care_completion_flow.dart`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Add `OccurrenceScheduleActionBar` (+ tests).
- Refactor `OccurrenceIdentityCard` left rail + wire action bar (reschedule/skip handlers lifted from `OccurrenceOpenActions`).
- `OccurrenceScreenBody`: phone order Identity → Away → Complete → Next open.
- `OccurrenceCompleteCareModule`: remove open-state header + completion date row; remove reschedule/skip from `OccurrenceOpenActions` (keep weight + Mark as done).
- l10n: Care date schedule actions use **Change date** (`rescheduleActionLabel`) not `occurrenceReschedule` where user-visible on this screen.
- Spec markdown in `changes/` capturing layout + decision IDs (proposed).

**Exit criteria:**

- [ ] Open occurrence: Change date + Skip under datetime in identity card; Mark as done alone in Complete module; no “This date” / completion-date row in open Complete module.
- [ ] Away module appears **above** Complete on phone (widget test scroll order or module keys).
- [ ] Family chip ≥48dp; pet name not bold on left rail.
- [ ] Semantics keys `occurrence_reschedule`, `occurrence_skip`, `occurrence_done` preserved.
- [ ] Files ≤500 lines; `pre-push-changed.sh` green.
- [ ] PR body: `Docs: N/A — changes/care-date-evolution-spec.md; canonical phase 3`.

**Note:** Phase 1 may temporarily regress overdue backdate until phase 2 merges — do **not** merge integration → `main` until all phases complete.

---

## Phase 2 — Completion flow (DN-3 parity)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-date-evolution-flow-b20d` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
flutter_app/lib/features/care_item/domain/done_decision.dart
flutter_app/lib/features/care_item/presentation/care_completion_flow.dart
flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_complete_care_module.dart
flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_open_actions.dart
flutter_app/test/features/care_item/domain/done_decision_test.dart
flutter_app/test/features/care_item/presentation/**
flutter_app/test/features/experience/presentation/care_item/occurrence/**
docs/domains/pet_care/changes/care-date-evolution-spec.md
.agents/plans/care-date-evolution-b20d.*
```

**forbidden_paths:** `server/**`, `db/**`, `e2e/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- Update `decideDone` / `CareCompletionFlow` so occurrence-screen Mark as done still prompts **When was this done?** when DN-3 applies (remove or narrow `onOccurrenceScreen` skip for DN-3 only; keep DN-2 skip where fields show on screen).
- Remove dead `_date` state from open path in `OccurrenceCompleteCareModule` if flow owns dates; keep closed-state completion editing.
- Unit tests: overdue after-done on occurrence screen triggers date sheet; fixed-schedule early completion unchanged.

**Exit criteria:**

- [ ] Widget or unit tests prove DN-3 path on occurrence screen without inline picker.
- [ ] `pre-push-changed.sh` green.
- [ ] No server/API changes.

---

## Phase 3 — Canonical sync, E2E, legacy debt issue

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-date-evolution-verify-b20d` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/pet_care/features/care-item-evolution.md
docs/domains/pet_care/changes/care-date-evolution-spec.md
docs/design/care-item-view-ui.md
e2e/playwright/pages/occurrence.page.ts
e2e/playwright/pages/care-item.page.ts
e2e/playwright/tests/care.agenda.spec.ts
flutter_app/test/features/care_item/**
.agents/plans/care-date-evolution-b20d.*
docs/debt/debt.md
```

**forbidden_paths:** `server/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- `/canonical-docs` sync: fold spec into `care-item-evolution.md` § Care date screen; add decision rows **D-CIE-037** (leaf confirmation model), **D-OSM-013** (module order), **D-OSM-014** (schedule actions in identity), **D-OSM-015** (Complete module without section header), **D-OSM-016** (reschedule placement superseding D-OSM-005 for open actions); delete `changes/care-date-evolution-spec.md` when fully delivered.
- Update `care-item-view-ui.md` — Care date leaf vs Care item shortcuts (one short subsection).
- E2E: locators for reschedule/skip placement; agenda journey if affected.
- **Debt issue (idea 3):** track deduplication of Mark done / Skip / Change date in `care_item_dates_section.dart` vs Needs attention — **no code change** in this phase unless ≤15-line comment pointer only.

**Exit criteria:**

- [ ] Canonical doc matches shipped UI; change doc deleted.
- [ ] E2E/page objects green in CI for touched specs.
- [ ] Debt issue filed with label `tech-debt` and link from control issue.
- [ ] Integration → `main` PR ready for `/babysit-uat`.

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "continue phase 3 on branch cursor/care-date-evolution-verify-b20d"
artifact_ref:
  branch: cursor/care-date-evolution-verify-b20d
  plan_path: .agents/plans/care-date-evolution-b20d.md
  plan_commit: a23e82c4fa6de3c01b962ad18a59bbfc94d71f7a
  snapshot_path: .agents/plans/care-date-evolution-b20d.snapshot.json
  snapshot_commit: a23e82c4fa6de3c01b962ad18a59bbfc94d71f7a
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1824"]
merge_commits: {}
debt_issue_refs: [1823]
```

## Final integration → main

After phase 3 merges to integration:

1. `./scripts/pre-push.sh` on integration tip.
2. Open PR `cursor/care-date-evolution-b20d-integration-b20d` → `main`.
3. `/babysit-uat` on that PR.
