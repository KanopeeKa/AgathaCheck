---
title: Care date screen — module layout (v2)
owner: Pet Care
audience: both
status: proposed
canonical_target: docs/domains/pet_care/features/care-item-evolution.md
related_plan: occurrence-screen-modules-5ec0
last_updated: 2026-10-08
tags: [pet_care, care_item, ui]
---

# Care date screen — module layout (v2)

**Status:** `proposed` — folds into [`care-item-evolution.md`](../features/care-item-evolution.md) § Care date screen when delivered by plan `occurrence-screen-modules-5ec0`.

**Supersedes (layout only):** Care date v1 sections in canonical doc (context tile + title row + labeled Status) — behaviour rules D-OCC-001 … D-OCC-017 remain unless amended below.

## Problem

The Care date (`OccurrenceScreen`) route still reads as a **flat form**: pet-first context tile, orphan date headline, labeled **Status** / **Actions**, and reschedule beside the date. Care Item detail already uses **warm canvas + bordered modules** (`CareItemDetailCanvas`, `CareItemModule`). Users should immediately see **one occurrence of a known Care**, not a second Care Item detail.

## Goal

Restructure the leaf screen into three module bands:

1. **Occurrence identity** — split card: care type (left) + this occurrence (right).
2. **Complete care** — completion date, primary **Mark as done**, secondary **Reschedule** + **Skip occurrence**.
3. **Next open date** — neutral navigation when another open occurrence exists after this one.

Preserve: Away block, all occurrence states (open, done, skipped, closed not recorded), weight requirements, undo rules, analytics keys where possible.

## Non-goals

- Server/API changes.
- Care Item detail redesign.
- Overflow (⋯) menu on Care date (still D-OCC-016).
- Plum-filled app bar unique to this screen (use shared experience shell).

---

## Layout (target)

### Chrome

| Element | Rule |
|---------|------|
| Shell | `ExperienceShellScaffold` (Pet Care), same back/`returnTo` as today |
| App bar title | **Care date** (D-OCC-001) — not care name |
| Menu | None (D-OCC-016) |
| Canvas | `CareItemDetailCanvas` + page padding 16 / bottom 32 |
| Wide (≥900px) | Identity full width; **Complete care** + **Next open date** side-by-side (flex 3:2), same breakpoint as Care Item |

### Module 1 — Occurrence identity card

Single `CareItemModule`. **Not** one tappable card for the whole row.

| Left column (~88–96dp) | Right column (flex) |
|------------------------|---------------------|
| `CareFamilyIcon` (no chip) + localized family label | **Care name** — `titleMedium`/`titleLarge`, w700, max 2 lines |
| Schedule affordance (see below) | One line: calendar icon + **datetime** `dd MMM yyyy – HH:mm` (locale via `intl`; omit time segment when null) |
| Tap → Care details (`openPetEventView`) | Next line: **status pill** + optional **relative overdue** (e.g. `11 days overdue`) — no "Status" label |
| | **Pet chip** below datetime/status: medallion + name (`CareItemPetContextTile` pattern); tap → pet profile (optional, same as Care Item) |
| | Series chips only when relevant: **Finished** / **Paused** (small, neutral) — hide `{n} open` |

**Schedule affordance (left column, below family label):**

| Condition | Icon | Semantics |
|-----------|------|-----------|
| `item.isFixedSchedule` (recurrence anchor from due date) | `Icons.autorenew` (or repeat) | Recurring care |
| Else: multiple open occurrences in `schedule.openOccurrences` | `Icons.autorenew` | Recurring / multi-date series |
| Else | `Icons.event` / calendar outline | Single planned date |

Do **not** use repeat for every dated care.

**Removed from v1 header:** `OccurrenceContextTile` (pet-first), `OccurrenceTitleRow`, `OccurrenceStatusSection` section labels, `{n} open` copy.

Optional link (recommendation): text button **View all dates** → Care details (replaces whole-card tap on occurrence facts).

### Module 2 — Complete care (state-dependent)

Wrapped in `CareItemModule` with header:

- Icon: plum circle + check (decorative) + title **Complete care** + one line helper: *Mark this occurrence as done or choose another option.* (l10n)

**Open (due / overdue / coming up / open not recorded):**

| Control | Rule |
|---------|------|
| Completion date | Labeled **Completion date**; show friendly "Today, …" when `completedOn` is as-of today |
| Primary | Filled **Mark as done** — key `occurrence_done` |
| Secondary row | Outlined **Reschedule** (`occurrence_reschedule`) + **Skip occurrence** (`occurrence_skip`) — icons optional |
| Weight | Unchanged requirement UX; field stays in this module |
| Reschedule | **Only here** — not in identity card (D-OSM-005) |

**Done:** linked weight row, editable completion date, Undo when `canUndoHere` — same rules D-OCC-010 … D-OCC-013.

**Skipped / closed not recorded:** existing copy and actions from `OccurrenceBlocks`; still inside module wrapper for visual consistency.

### Module 3 — Next open date (navigation)

`CareItemModule`, **neutral** styling (no plum fill on card body).

Show when:

- `schedule` present,
- series not finished,
- exists another **open** occurrence with scheduled date **strictly after** current occurrence's date (or same date with distinct id later in sort order),
- target id ≠ current id.

Content:

- Label: **Next open date** (not "Next occurrence" if that implies calendar series — honest when stack has earlier missed dates).
- Bold datetime line (same format as identity card).
- Trailing **View** / chevron → `openOccurrenceScreen` for that id.

Hide when: no successor, one-off with single open date, series completed.

When `openCount > 1` and earlier dates remain open, identity module may show **View all dates** → Care details Needs attention (recommendation).

### Away (unchanged scope)

`OccurrenceAbsenceSection` remains a **conditional module** between Complete care and Next open date (D-OCC-014, D-OCC-015).

---

## Decision log (proposed — fold into canonical on delivery)

| ID | Decision |
|----|----------|
| D-OSM-001 | Care date uses `ExperienceShellScaffold` + `CareItemDetailCanvas`; app bar title **Care date** |
| D-OSM-002 | Replace v1 header widgets with **Occurrence identity** `CareItemModule` (split type / occurrence) |
| D-OSM-003 | Schedule affordance: repeat only for fixed schedule or multi-open; else calendar/event |
| D-OSM-004 | Pet medallion **below** datetime + status on identity card |
| D-OSM-005 | **Reschedule** only in Complete care module for open actionable states |
| D-OSM-006 | **Next open date** navigates to next **open** occurrence by schedule sort, not theoretical calendar slot |
| D-OSM-007 | Remove `{n} open` from Care date header |
| D-OSM-008 | Section labels **Status** / **Actions** removed; structure replaces copy |
| D-OSM-009 | New l10n: `occurrenceCompleteCareTitle`, `occurrenceCompleteCareSubtitle`, `occurrenceCompletionDateLabel`, `occurrenceDaysOverdue`, `occurrenceNextOpenDate`, `occurrenceViewNext`, `occurrenceViewAllDates` |
| D-OSM-010 | E2E: keep `occurrence_screen`, `occurrence_done`, `occurrence_skip`, `occurrence_reschedule`; add `occurrence_identity_card`, `occurrence_next_open`; deprecate `occurrence_about_item` locator in favour of identity card link semantics |

---

## Acceptance criteria

1. Visual parity with Care Item modules (border, radius, canvas) on phone and web.
2. Immediate distinction from Care Item: app bar **Care date**, identity card shows **this** datetime + status, not series schedule editor.
3. Open occurrence: Mark as done + Reschedule + Skip in one module; no duplicate Reschedule in header.
4. All v1 state/action rules (D-OCC-006 … D-OCC-017) still hold unless listed above.
5. Widget tests cover identity card, action module layout, next-open visibility rules.
6. Playwright `OccurrencePage` updated; at least one smoke path still reaches Mark as done.
7. Canonical doc synced; this file deleted when fully delivered.

---

## Implementation map

| Artifact | Path |
|----------|------|
| Screen orchestration | `flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_screen.dart` |
| Identity card | `occurrence_identity_card.dart` (new) |
| Complete care module | `occurrence_complete_care_module.dart` (new; delegates to refactored `occurrence_blocks.dart`) |
| Next navigation | `occurrence_next_open_module.dart` (new) |
| Next occurrence helper | `flutter_app/lib/features/care_item/domain/next_open_occurrence.dart` (new, pure) |
| Delete or slim | `occurrence_context_tile.dart`, `occurrence_title_row.dart`, `occurrence_status_section.dart` |

---

## Risks

| Risk | Mitigation |
|------|------------|
| `occurrence_about_item` E2E breakage | Parallel semantics id on care-type tap; update page object in phase 3 |
| File size >500 | Split widgets per modularity rule |
| Wrong "next" when stack has earlier overdue | Label **Next open date** + link to Care details when multiple open |
