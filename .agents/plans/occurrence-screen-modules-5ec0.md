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

Deliver the **module-based Care date screen** per [`docs/domains/pet_care/changes/occurrence-screen-modules-spec.md`](../../docs/domains/pet_care/changes/occurrence-screen-modules-spec.md) (review amendments 2026-10-08).

**One verifiable outcome:** Care date reads as **one occurrence of a known Care** (identity → this date → away → next open), aligned with Care Item surface tokens, without API changes.

**Integration:** Two phase PRs → `cursor/occurrence-screen-modules-5ec0-integration-5ec0`, then one PR → `main` (`/babysit-uat`).

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `occurrence-screen-modules-5ec0` |
| **created** | 2026-10-08 |
| **base_branch** | `cursor/occurrence-screen-modules-5ec0-integration-5ec0` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Canonical docs

| Path | When |
|------|------|
| `docs/domains/pet_care/changes/occurrence-screen-modules-spec.md` | Source during build |
| `docs/domains/pet_care/features/care-item-evolution.md` | Phase 2 Mode A fold + delete changes spec |

**Docs gate per PR:**

- Phase 1 PR: `Docs: N/A — behaviour spec in changes/occurrence-screen-modules-spec.md; canonical fold in phase 2`.
- Phase 2 PR: full `/canonical-docs` sync.

## Router

| Field | Value |
|-------|-------|
| **router_risk** | R1 |
| **protocols** | `accessibility`, `flutter-mobile`, `testing`, `documentation` |
| **verification** | `check_file_size.js`, `flutter analyze`, `pre-push-changed.sh`, widget tests with code, E2E locator updates |

## Sanity check

**Result:** `proceed` (revised after review — two phases, no mid-integration Reschedule regression).

## Review resolutions (2026-10-08)

| # | Resolution |
|---|------------|
| 1–2 | `next_open_occurrence.dart` uses `openOccurrences` list order + `compareTo`; unit tests pin rules; non-open states use step 3 in spec |
| 3 | Stay on screen after commands (matches `CareCompletionFlow` + `onChanged`); AC + widget test |
| 4 | Repeat icon from `intervalDays` / `repeatsDailyOrMore`, not `isFixedSchedule` or open count |
| 5 | **Single phase 1 ships full UI** including Reschedule in action module (no partial header tear-out) |
| 6 | Docs gate per PR (above) |
| 7 | Wide layout: Away full width; This date full width when Next hidden |
| 8 | No left-column tap; `occurrence_open_care_details` only; decorative header icon excluded |
| 9 | Completion “today” from `asOf.date`; optional yesterday |
| 10 | ICU plural overdue; hidden when not overdue |
| — | Two phases total (UI+tests, then E2E+canonical) |
| — | No `occurrence_next_open_tapped` analytics in v2 (D-OSM-012) |

## Autonomy (before grant)

1. Review updated spec.
2. `validate_execute_plan_snapshot.js --fix-hash`
3. `init-control-issue occurrence-screen-modules-5ec0`
4. Push integration branch from `main`
5. `approve-autonomous occurrence-screen-modules-5ec0` on control issue; set `autonomy: active`, timestamps, real `control_issue`
6. `/execute-plan occurrence-screen-modules-5ec0`

---

## Phase 1 — Module layout (full UI + unit/widget tests)

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/occurrence-screen-modules-ui-5ec0` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/pet_care/changes/occurrence-screen-modules-spec.md
flutter_app/lib/features/experience/presentation/care_item/occurrence/**
flutter_app/lib/features/care_item/domain/next_open_occurrence.dart
flutter_app/lib/l10n/**
flutter_app/test/features/care_item/domain/next_open_occurrence_test.dart
flutter_app/test/features/care_item/presentation/occurrence_*.dart
flutter_app/test/features/experience/presentation/care_item/occurrence/**
.agents/plans/occurrence-screen-modules-5ec0.*
```

**forbidden_paths:** `server/**`, `.github/workflows/**`, `db/**`, `e2e/**`

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope (atomic — no Reschedule regression):**

- `ExperienceShellScaffold` + `CareItemDetailCanvas`.
- `OccurrenceIdentityCard` per spec (no left tap; `occurrence_open_care_details`).
- Split `occurrence_blocks.dart` → open/closed action files + `OccurrenceCompleteCareModule` (**This date**).
- Reschedule in action row with Skip; remove v1 header widgets entirely in this phase.
- `OccurrenceNextOpenModule` + `next_open_occurrence.dart` + tests.
- Away module placement per wide-layout table.
- l10n EN/FR including plural overdue.
- Widget tests: identity, actions, next-open visibility, stay-on-screen after done (mocked).
- Domain unit tests for next-open helper.

**Exit criteria:**

- [ ] All modules on canvas; D-OCC amendments satisfied in UI.
- [ ] Open occurrence has Reschedule in This date module only.
- [ ] Files ≤500 lines each.
- [ ] `pre-push-changed.sh` green.
- [ ] PR documents `Docs: N/A — … phase 2`.

---

## Phase 2 — E2E locators + canonical sync

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/occurrence-screen-modules-verify-5ec0` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/pet_care/features/care-item-evolution.md
docs/domains/pet_care/changes/occurrence-screen-modules-spec.md
e2e/playwright/pages/occurrence.page.ts
e2e/playwright/pages/care-item.page.ts
e2e/playwright/pages/away-planning.page.ts
e2e/playwright/tests/care.agenda.spec.ts
flutter_app/test/features/care_item/**
.agents/plans/occurrence-screen-modules-5ec0.*
```

**forbidden_paths:** `server/**`

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- Playwright: replace `occurrence_about_item` with `occurrence_open_care_details` / `occurrence_identity_card`.
- Mode A: update `care-item-evolution.md` (layout, D-OCC amendments, D-OSM-*).
- Delete `occurrence-screen-modules-spec.md`.
- Open integration → `main` PR; `/babysit-uat`.

**Exit criteria:**

- [ ] E2E page objects and agenda/away specs updated.
- [ ] Canonical doc synced; changes spec removed.
- [ ] Integration PR to `main` merged with pre-UAT green.

---

## Final merge

Integration → `main`: `./scripts/pre-push.sh`, `/babysit-uat`.

## Analytics

Unchanged: `occurrence_screen_opened`, `care_completion_date_changed`. **No** `occurrence_next_open_tapped` in v2.

## Runtime state

```yaml
autonomy: halted
next_action: approve-autonomous after review sign-off
```

## Checklist before `approve-autonomous`

- [ ] Spec review (Claude checklist items 1–10) accepted
- [ ] Snapshot validates; control issue created
- [ ] Integration branch on origin
