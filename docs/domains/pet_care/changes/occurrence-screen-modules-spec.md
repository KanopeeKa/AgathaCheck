---
title: Care date screen — module layout (v2)
owner: Pet Care
audience: both
status: proposed
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-item-evolution.md
related_plan: occurrence-screen-modules-5ec0
last_updated: 2026-10-08
tags: [pet_care, care_item, ui]
---

# Care date screen — module layout (v2)

**Status:** `proposed` — folds into [`care-item-evolution.md`](../features/care-item-evolution.md) § Care date screen when delivered by plan `occurrence-screen-modules-5ec0`.

**Supersedes (layout only):** Care date v1 sections (context tile + title row + labeled Status / Actions). Behaviour rules **D-OCC-001 … D-OCC-017** remain unless listed in §Amendments to D-OCC.

## Problem

The Care date (`OccurrenceScreen`) route reads as a **flat form**. Care Item detail already uses **warm canvas + bordered modules** (`CareItemDetailCanvas`, `CareItemModule`). Users should immediately see **one occurrence of a known Care**, not a second Care Item detail.

## Goal

Restructure into module bands:

1. **Occurrence identity** — split card: care type (left, non-navigating) + this occurrence (right).
2. **This date** (action module) — completion date, **Mark as done**, **Reschedule**, **Skip occurrence** (open states).
3. **Next open date** — neutral navigation when a later open slot exists in the schedule list.
4. **Away** — unchanged conditional block.

## Non-goals

- Server/API changes.
- Care Item detail redesign.
- Overflow menu (D-OCC-016).
- Plum-filled app bar unique to this screen.

---

## Amendments to D-OCC (layout)

| ID | v1 (canonical) | v2 |
|----|----------------|-----|
| D-OCC-002 | Context tile → Care details | Identity card; **View care details** text button only (semantics `occurrence_open_care_details`) |
| D-OCC-003 | Pet + care name on tile; `{n} open` | Care name on identity right; pet chip below datetime; **no `{n} open`** |
| D-OCC-004 | Title row: date/time + Reschedule | Datetime on identity card; **no Reschedule in header** |
| D-OCC-005 | Order: Status → Away → Actions | Identity → **This date** (actions) → Away → **Next open date**; no section labels **Status** / **Actions** |

---

## Post-command navigation (required behaviour)

**Today (code):** Mark as done (`CareCompletionFlow.done` with `onOccurrenceScreen: true`), Skip, and Reschedule all call `onChanged()` → `_load()` and **stay on the Care date route**. The screen re-renders for the new occurrence state (e.g. Done layout). No automatic `pop`.

**v2:** Preserve this. Do **not** pop after success.

| After | Screen |
|-------|--------|
| Mark as done / Skip / Reschedule success | Same route; refreshed `OccurrenceDetail`; modules update (e.g. Done actions, next-open target) |
| Back | Unchanged shell `returnTo` / default Care details |

**Acceptance:** Integration test or widget test asserts `OccurrenceScreen` remains mounted after mocked successful Mark as done (no `Navigator.pop`).

---

## Layout

### Chrome

| Element | Rule |
|---------|------|
| Shell | `ExperienceShellScaffold` (Pet Care) |
| App bar | **Care date** (D-OCC-001) |
| Canvas | `CareItemDetailCanvas`, padding 16 / bottom 32 |

### Wide layout (≥ `kCareItemTwoColumnBreakpoint`, 900px)

| Row | Content |
|-----|---------|
| 1 | Identity card — full width |
| 2 | Away module — **full width** when visible (never squeezed into 3:2 row) |
| 3 | If **Next open date** visible: `Row` with **This date** `Expanded(flex: 3)` + Next open `Expanded(flex: 2)` |
| 3 alt | If Next open **hidden**: **This date** — **full width** (no empty 2/5 gutter) |

Phone: single column — Identity → This date → Away → Next open.

### Module 1 — Occurrence identity

`CareItemModule`. **Left column is not tappable** (avoids hidden tap target + duplicate paths to Care details).

| Left (~88–96dp) | Right (flex) |
|-----------------|--------------|
| `CareFamilyIcon` + family label | **Care name** (titleMedium/Large, w700) |
| Schedule affordance (decorative + semantics) | Datetime line: `formatOccurrenceInstant` / locale `DateFormat` skeleton (not hardcoded `dd MMM`) |
| | Status **pill** + `occurrenceDaysOverdue` when overdue only (ICU plural EN/FR); pill label must carry status without relying on colour |
| | Pet chip (`CareItemPetContextTile`); tap → pet profile |
| | Finished / Paused chips when applicable |
| | Text button **View care details** → `openPetEventView` (`occurrence_open_care_details`) |

**Schedule affordance (left, below label):** derive from **schedule definition**, not open count or `isFixedSchedule` alone.

| Condition | Icon | Semantics label |
|-----------|------|-----------------|
| `schedule.intervalDays != null` **or** `schedule.repeatsDailyOrMore` | `Icons.autorenew` | Recurring care |
| Else | `Icons.event_outlined` | Planned date |

`isFixedSchedule` means fixed vs after-it's-done scheduling (`care_done_tapped` `schedule_type`), **not** “recurring”. Do not use open-occurrence count for the icon (unstable as user completes dates).

**Removed:** `OccurrenceContextTile`, `OccurrenceTitleRow`, `OccurrenceStatusSection`, `{n} open`.

**View all dates:** **Not** on identity card. When `openOccurrences.length > 1`, show helper line only on **Next open date** module: “Other open dates are on this care item.” + same **View care details** pattern (or reuse one link — do not duplicate two different links to Care details on one screen).

### Module 2 — This date (actions)

`CareItemModule`. Header:

- Decorative plum check icon — `ExcludeSemantics`.
- Title **This date** (l10n `occurrenceThisDateTitle`) for **open** states only.
- **No subtitle** (buttons are self-explanatory).
- Done / skipped / closed-not-recorded: title **Record** or state-specific copy per existing strings; no “mark as done” helper.

**Open states:** completion date, Mark as done, Reschedule + Skip in one module (`occurrence_reschedule` lives here only).

**Completion date friendly label:** Compare calendar day to `detail.item.asOf.date` (pet home **as-of**, not `DateTime.now()`). “Today, …” when equal; “Yesterday, …” when as-of minus one day; else neutral formatted date.

**File split (required up front):** `occurrence_blocks.dart` is ~470 lines. Before wrapping:

- `occurrence_open_actions.dart` — open-state fields + buttons.
- `occurrence_closed_actions.dart` — done / skipped / closed-not-recorded.
- `occurrence_complete_care_module.dart` — module chrome + dispatches by state.

### Module 3 — Next open date

Neutral `CareItemModule`. Visible for **all occurrence states** (open, done, skipped, closed-not-recorded) when a successor exists.

**Helper:** `nextOpenOccurrenceAfter` in `next_open_occurrence.dart` — unit-tested.

**Algorithm (single rule):**

1. Let `open = schedule.openOccurrences` (already sorted ascending: `date`, then `time`; null time sorts first on that day — `OpenOccurrence.compareTo`).
2. If `currentId` is in `open` at index `i` and `i + 1 < open.length` → return `open[i + 1]` (**list order tiebreak**; no id compare).
3. If `currentId` **not** in `open` (done, skipped, closed, etc.): build a sort key from current occurrence’s `date` + `time`; return the **first** `o` in `open` where `o.compareTo(currentKey) > 0`. If `compareTo == 0` for multiple (duplicate instant — rare), take the **first in list** whose `id != currentId`.
4. If none → hide module.

Do **not** document “sort by id” or “strictly after date only” separately from the above.

**Content:** label **Next open date**, bold datetime, **View** → `openOccurrenceScreen`. Semantics `occurrence_next_open`.

When `open.length > 1` and user is viewing an overdue slot with earlier open dates still in the list, the label stays **Next open date** (honest: next in sorted open list, not “next calendar series slot”).

### Away

`OccurrenceAbsenceSection` in its own module, **full width** on wide layouts, **after** This date and **before** Next open on phone; on wide, **above** the This date / Next open row (see table).

---

## Decision log (proposed)

| ID | Decision |
|----|----------|
| D-OSM-001 | `ExperienceShellScaffold` + `CareItemDetailCanvas`; app bar **Care date** |
| D-OSM-002 | Identity `CareItemModule`; left column not tappable |
| D-OSM-003 | Repeat icon when `intervalDays != null` or `repeatsDailyOrMore`; else event icon |
| D-OSM-004 | Pet chip below datetime + status |
| D-OSM-005 | Reschedule only in This date module (open) |
| D-OSM-006 | Next open via list-index + `compareTo` rules in §Module 3 |
| D-OSM-007 | No `{n} open` on Care date |
| D-OSM-008 | No Status/Actions section labels |
| D-OSM-009 | l10n: `occurrenceThisDateTitle`, `occurrenceCompletionDateLabel`, `occurrenceDaysOverdue` (plural), `occurrenceNextOpenDate`, `occurrenceViewNext`, `occurrenceOpenCareDetails`, `occurrenceOtherOpenDatesHint` |
| D-OSM-010 | Semantics: `occurrence_identity_card`, `occurrence_open_care_details`, `occurrence_next_open`; retire `occurrence_about_item` / `occurrence_context_tile` in E2E |
| D-OSM-011 | Stay on screen after Mark as done / Skip / Reschedule; refresh via `onChanged` |
| D-OSM-012 | No new analytics event for View next in v2 |

---

## Acceptance criteria

1. Module visual parity with Care Item detail (tokens, radius, canvas).
2. Distinct from Care Item: **Care date** app bar + occurrence identity datetime.
3. Open occurrence: Reschedule + Skip + Mark as done in one module; never in header.
4. D-OCC action rules unchanged except §Amendments.
5. `next_open_occurrence_test.dart` covers: in-list successor, not-in-list (done), no successor, duplicate date/time list order.
6. Widget tests ship **with** UI in phase 1 (same PR).
7. E2E: update `occurrence.page.ts`, `care-item.page.ts`, `care.agenda.spec.ts`, `away-planning.page.ts`.
8. Phase 1 PR body: `Docs: N/A — integration branch; canonical fold in phase 2`. Phase 2: Mode A sync + delete this file.
9. After Mark as done (mocked), screen does not pop.

---

## Implementation map

| Artifact | Path |
|----------|------|
| Screen | `occurrence_screen.dart` |
| Identity | `occurrence_identity_card.dart` |
| Actions shell | `occurrence_complete_care_module.dart` |
| Action bodies | `occurrence_open_actions.dart`, `occurrence_closed_actions.dart` (split from `occurrence_blocks.dart`) |
| Next nav | `occurrence_next_open_module.dart` |
| Domain | `care_item/domain/next_open_occurrence.dart` |
| Delete | `occurrence_context_tile.dart`, `occurrence_title_row.dart`, `occurrence_status_section.dart` |

---

## Risks

| Risk | Mitigation |
|------|------------|
| E2E locator drift | D-OSM-010; all Playwright files listed in phase 2 `allowed_paths` |
| File size | Mandatory split before module wrap |
| Duplicate datetime in open list | Index-based successor when current is open; documented rare case |
