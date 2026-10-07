---
title: Care date screen (occurrence leaf) v1
---

# occurrence-screen-context-6b05

## Goal

Implement the agreed Care date screen layout: context tile, title + Reschedule, status, away block, unified actions. **Canonical spec:** `docs/domains/pet_care/features/care-item-evolution.md` § Care date screen (folded 2026-10-07). Widget tests and E2E locator updates.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `occurrence-screen-context-6b05` |
| **base_branch** | `cursor/occurrence-screen-context-6b05-integration-6b05` |
| **default_merge_mode** | `auto` |

## Phases

### Phase 1 — Spec and core Care date layout

**branch:** `cursor/occurrence-screen-context-core-6b05`  
**allowed_paths:** `docs/domains/pet_care/features/care-item-evolution.md`, `flutter_app/lib/features/experience/presentation/care_item/occurrence/**`, `flutter_app/lib/l10n/**`, `.agents/plans/occurrence-screen-context-6b05.*`

### Phase 2 — Away block, tests, E2E

**branch:** `cursor/occurrence-screen-context-tests-6b05`  
**allowed_paths:** same occurrence paths, `flutter_app/test/features/care_item/**`, `e2e/playwright/pages/occurrence.page.ts`, `e2e/playwright/pages/care-item.page.ts`

## Autonomy

Granted in user chat 2026-10-06 — full integration branch, single PR to `main`, no pause.

## Acceptance criteria (Care date v1)

1. App bar title **Care date**; back returns per shell `returnTo`.
2. Context tile opens Care details; shows pet medallion + name, care name, lifecycle chip, `{n} open` (hidden when finished).
3. Title row shows scheduled date/time only; **Reschedule** visible for open actionable doses (not closed-not-recorded).
4. Status pill matches occurrence state (due, overdue, done, skipped, not recorded, coming up).
5. Away block only for open occurrence dates inside an absence window; **keep_date** is absence-wide with explainer.
6. Open actions: completion date + **Mark as done** (filled) + **Skip** (outlined); no ⋯ menu.
7. Done: editable completion date; Undo label from `lastAction` when `canUndoHere`.
8. Finished series: static copy only when `!canUndoHere`.
9. E2E semantics: `occurrence_about_item`, `occurrence_screen`, `occurrence_reschedule` stable for Playwright.
