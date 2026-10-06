---
title: Spec — Care Item context header and app bar title
owner: Product / Design
audience: both
status: agreed
last_updated: 2026-10-06
tags: [pet_care, care_item, ux, accessibility, l10n]
---

# Spec — Care Item context header and app bar title

**Status:** **agreed** — product decisions 2026-10-06; **UI pending implementation** (Flutter route still uses item name in app bar and `PetEventPetCard` until implementation PR).  
**Surface:** Flutter Care Item detail (`/pet/:petId/events/:entryId`) — `CareItemDetailScreen`, `CareItemDetailBody`, new `care_item_context_strip.dart`, new `care_item_pet_context_tile.dart`, related l10n EN/FR. No server change in this programme.

**Related**

| Document | Relationship |
|----------|----------------|
| [care-item-evolution.md](../features/care-item-evolution.md) | § Care item view → Header; lifecycle D-CIE-018 |
| [care-item-view-ui.md](../../../design/care-item-view-ui.md) | Pet context module |
| [terminology.md](../../../design/terminology.md) | `careItemScreenTitle` |
| [care-item-bulk-scope-spec.md](./care-item-bulk-scope-spec.md) | Same route; Needs attention semantics unchanged |

**Explicitly out of scope (separate requirements)**

- Occurrence screen app bar and header rework
- Create/Edit care form titles
- Notification deep-link titles
- Multi-pet / dashboard entry-path wayfinding review
- Changes to `UnifiedPetTile`, `PetCard`, or My Pets dashboard tiles
- **Wire/API `closed_reason` (or equivalent)** to distinguish user **Archive** from natural **Finished** — follow-up §10 (required before an **Archived** strip chip)

## 1. Problem

On the Care Item detail route today:

1. The **app bar title** is the care item name (e.g. "Heart tablet"). That duplicates the identity users already chose from the agenda and competes with the **Needs attention** hero for attention.
2. The **pet block** is a large module (`PetEventPetCard` inside `CareItemModule`) with limited information and **no navigation** to the pet profile.
3. On **wide layouts** (≥ `kCareItemTwoColumnBreakpoint`, 900 logical px), the pet module sits in the **side column**, separating pet context from the action column.

Users need a calmer hierarchy: **what needs doing now** first, with **who** (pet) and **what** (named care) as compact, scannable context.

## 2. Outcome

**Generic app bar (`careItemScreenTitle`), scrollable context strip** (pet chip + care name + decorative category icon + optional **short status chip**), **no** `PetEventPetCard` module. Pet tap via **`openPetDetail`**. **Needs attention** owns lifecycle **dates and actions**; strip chips are labels only (D-CIH-007).

## 3. Locked decisions

| # | Decision |
|---|----------|
| D-CIH-001 | App bar: **`careItemScreenTitle`** — Care details / Détail du soin (not `careItemDetailsTitle`, the Details module header) |
| D-CIH-002 | Care item **name** in the strip (max two lines, ellipsis) |
| D-CIH-003 | Pet chip tap: **`openPetDetail(context, petId)`** with `returnTo` = current shell location |
| D-CIH-004 | **`CareItemPetContextTile`** in `care_item_pet_context_tile.dart` — reuses **photo helper only**. **Do not** modify `UnifiedPetTile`, `PetCard`, or `PetTileDimensions` |
| D-CIH-005 | Species on pet chip **optional**; pet **name always visible** to sighted users (no avatar-only layout) |
| D-CIH-006 | **Category icon** — visual only; family name in care-name **header** semantics label only |
| D-CIH-007 | **Strip:** at most **one** status chip (no dates, no actions). **Needs attention** (and evolution-assigned modules) own paused/finished/archived **copy and actions** |
| D-CIH-008 | Strip **not sticky**; scrolls away |
| D-CIH-009 | App bar title is **not** "Care routine" |
| D-CIH-010 | Pet chip semantics: **button**, label = pet name (+ species if shown); no "Opens profile" suffix |
| D-CIH-011 | **`Semantics(header: true)` on care name `Text` only** — not on the whole strip |
| D-CIH-012 | **`CareItemContextStrip`** in `care_item_context_strip.dart`; keep `care_item_detail_body.dart` under 500 lines |
| D-CIH-013 | **Status chip priority** (at most one): **Finished > Paused**. **No Archived chip** until API exposes user Archive vs natural finish (§5.2.2, §10) |
| D-CIH-014 | **Wide shell content header:** when Pet Care uses leading nav (viewport **≥ `PetCarePrimaryDestinations.compactBreakpoint`**, 600 logical px — i.e. `!PetCarePrimaryDestinations.isCompact(width)`), the shell shows `screenTitle` as **`titleLarge` w700** in the content chrome. Strip care name uses **`theme.textTheme.titleMedium` with `fontWeight: FontWeight.w700`**. Below 600 px, strip care name uses **`titleLarge`**. This breakpoint is **independent** of the Care Item two-column breakpoint (900 px); one-column body with `titleMedium` strip title between 600–899 px is **intentional** |

## 4. Scope

### In scope

- **`careItemScreenTitle`** on every state of this route (AC-2), including **migrating bare `Scaffold` shells** (pets loading/error/**not found**) to `ExperienceShellScaffold` + route title in `care_item_detail_screen.dart`
- `CareItemContextStrip` + `CareItemPetContextTile` (new files)
- Replace `petModule` with strip; wide layout per §5.3
- Status chip logic §5.2.2; l10n §6
- Widget tests, semantics contract, Playwright audit §9

### Out of scope

- Occurrence screen, agenda entry paths, notifications
- `PetEventPetCard` on other routes
- Dashboard / My Pets tile changes (AC-21)
- **Archived** strip chip and distinct **Archived** Needs attention hero until `closed_reason` (or equivalent) ships (§10)

## 5. UX specification

### 5.1 App bar

| Element | Rule |
|---------|------|
| Title | `l.careItemScreenTitle` only |
| Actions | Unchanged (Edit, ⋯) |
| Back | Unchanged |

Care item name **not** in app bar after implementation.

**Wide / leading-nav:** See **D-CIH-014** (600 px shell breakpoint, not 900 px).

**Browser tab:** May read "Care details" if shell maps `screenTitle` to document title — acceptable v1 (risk §11).

### 5.2 Context strip

#### 5.2.0 Default (horizontal) layout

```
┌─────────────────────────────────────────────────────────┐
│  [ Pet chip ]   Care item name (1–2 lines)      [icon] │
│                 [ status chip ]                          │
└─────────────────────────────────────────────────────────┘
```

| Part | Rule |
|------|------|
| Container | Not `CareItemModule`; inside existing scroll view padding (typically **16 px** — do not add a second horizontal inset) |
| Pet chip | `CareItemPetContextTile`: **40 px** circular avatar + **one-line** pet name; row height **≥ 48 px**; tap → `openPetDetail` |
| Care name | Typography per **D-CIH-014**; max 2 lines, ellipsis |
| Category icon | Trailing on care-name row; non-interactive |
| Status chip | §5.2.2; muted chip on its **own line** under the care name (horizontal layout) |
| Gap before first module | **16 px** |

**Scrolling:** Strip scrolls off with content (D-CIH-008).

#### 5.2.1 Responsive stacked layout (mandatory fallback)

Measure width with the strip's **`LayoutBuilder` constraints** (`constraints.maxWidth`), not `MediaQuery` alone, so padding is included correctly.

When strip width **≤ 360** logical px **or** `MediaQuery.textScalerOf(context).scale(14) / 14 ≥ 1.3`:

**Row 1:** Pet chip — 40 px avatar + pet name (≥ 48 px tall), full strip width, tappable.

**Row 2:** Care name (up to 2 lines) with category icon trailing, or icon on a line below the care name if needed to avoid overflow.

**Row 3 (when a chip applies):** Status chip on its **own line** under the care name.

Pet name remains **visible** for sighted users in all breakpoints.

#### 5.2.2 Status chip — source and priority

Show **at most one** chip. Priority: **Finished > Paused**.

| Chip | Show when | l10n |
|------|-----------|------|
| **Finished** | `entry.status == 'completed'` **or** `isHealthEntrySeriesClosed(entry)` (see `isHealthEntrySeriesClosedAt` in `health_entry_series_closed.dart`) | `careItemStatusFinished` |
| **Paused** | `entry.isPaused` **and** Finished chip does not apply | **`careItemPausedStatus`** (existing) |

**Why there is no Archived chip (v1):** On the server, user **Archive** (`closeSeriesCommand`) and natural **finish** (`finishIfNothingLeft`) both set `health_entries.status = 'completed'`. The client cannot distinguish them without a new field (§10). Labelling `completed` as "Archived" would mislabel finished one-offs (e.g. a completed vet visit).

**Needs attention (same limitation):** Until `closed_reason` (or equivalent) exists, the UI **cannot** show separate evolution rows for "Archived + Restore" vs "Finished · date" based on wire data alone. Implementation keeps **current** closed/paused module behaviour; this spec does not require new Needs attention copy for Archived vs Finished until the API follow-up lands.

When **Active** (no chip predicates): **no** status chip.

### 5.3 Wide layout (≥ 900 logical px)

Full-width strip above two-column body; **no** pet module in side column.

### 5.4 Module order

**Unchanged from current `CareItemDetailBody`** after inserting the strip where `petModule` was:

- Mobile one column: strip → needs attention → `sideScheduleAbsenceColumn()` → details module (incl. established when applicable) → history.
- `sideScheduleAbsenceColumn()` order is **conditional** (absence-before-schedule vs schedule-before-absence) and always includes the observation/weight slot between schedule and absence per existing code — do **not** reorder modules to match evolution's Agatha slot (not present in body today).

## 6. Copy and l10n

| Key | EN | FR | Use |
|-----|----|----|-----|
| `careItemScreenTitle` | Care details | Détail du soin | App bar |
| `careItemPausedStatus` | Paused | En pause | Strip chip — **reuse** |
| `careItemStatusFinished` | Finished | Fini | Strip chip |

Do **not** add `careItemStatusArchived` until §10 API ships.

Long strings (`careItemPausedSince`, `careItemPausedUntil`, …) remain in Needs attention / date modules only.

## 7. Accessibility

| Requirement | Detail |
|-------------|--------|
| Care name | `Semantics(header: true)` on title `Text`; label includes care name + family (from category) |
| Pet chip | `Semantics(identifier: 'care_item_pet_tile')`; button; label = pet name (+ species if shown) |
| Category icon | Exclude from separate semantics / focus |
| Touch | Pet chip ≥ 48×48 |

## 8. Acceptance criteria

### App bar and route title

- **AC-1:** Loaded: app bar shows `careItemScreenTitle`, not item name.
- **AC-2:** **Every** state of `/pet/:petId/events/:entryId` shows `careItemScreenTitle` in `ExperienceShellScaffold`, including pets **loading**, **error**, and **pet not found** (migrate all bare `Scaffold` branches in `CareItemDetailScreen`).

### Context strip

- **AC-3:** Item name in strip, not app bar.
- **AC-4:** Max two lines for care name, then ellipsis.
- **AC-5:** Category icon visible; not separately focusable.
- **AC-6:** Paused → chip text from **`careItemPausedStatus`** only; dates in Needs attention.
- **AC-7:** `status == 'completed'` or series closed → **Finished** chip (`careItemStatusFinished`) only — **never** an "Archived" chip in this programme.
- **AC-8:** Active → no chip.

### Pet chip

- **AC-9:** `openPetDetail` + `returnTo`; Back returns to Care Item.
- **AC-10:** No dashboard status ("All set", etc.).
- **AC-11:** No `PetEventPetCard` on this route body.

### Layout

- **AC-12:** Strip not in `CareItemModule`.
- **AC-13:** Needs attention first module below strip (mobile).
- **AC-14:** Wide: strip full width above columns; no side pet module.
- **AC-15:** Strip scrolls away.

### Accessibility

- **AC-18:** Pet = button + name; care name = heading; not merged.

### Responsive

- **AC-19:** At strip width 320 px **or** text scale ≥ 1.3: **stacked** layout §5.2.1; pet name visible; chip on line under care name; no horizontal overflow.

### Typography (wide shell)

- **AC-22:** When viewport width **≥ 600** (`!PetCarePrimaryDestinations.isCompact`), strip care name **`titleMedium` w700**; when **&lt; 600**, **`titleLarge`**.

### Regression and isolation

- **AC-16:** Edit, ⋯, Needs attention, route URL unchanged.
- **AC-17:** No new user-visible "occurrence".
- **AC-20:** Strip in `care_item_context_strip.dart`.
- **AC-21:** My Pets / dashboard `UnifiedPetTile` / `PetCard` **unchanged**.

### Chip logic

- **AC-23:** `status == 'completed'` shows **Finished**, not Archived. Paused chip only when Finished does not apply.

## 9. Verification checklist (implementation PR)

| Layer | Action |
|-------|--------|
| Widget | Strip, chip rules, stacked breakpoint (LayoutBuilder width), typography at 600 px |
| Widget | `CareItemDetailScreen` — AC-2 all scaffold branches |
| Widget | Dashboard tile tests unchanged |
| Semantics | `care_item_pet_tile` + header |
| Playwright | Audit `care-item.page.ts` for entry-name-in-title assumptions |
| l10n | Keys §6 only |
| Manual | Completed one-off shows Finished chip; stacked layout |

## 10. Open follow-ups

| Topic | Notes |
|-------|--------|
| **`closed_reason` (or equivalent) on `health_entries`** | Distinguish user **Archive** (`closeSeriesCommand`) from **finishIfNothingLeft**; enables **Archived** strip chip and evolution-accurate Needs attention. **Named blocker** for Archived UX |
| Occurrence screen | Separate requirement |
| Agenda / notifications | Separate |

## 11. Risks

| Risk | Mitigation |
|------|------------|
| Finished chip on user-archived items | Accept v1; API follow-up §10; product copy in menu still says Archive |
| Generic tab title | Strip title + AC-3/4/18 |
| Twin large headings | D-CIH-014, AC-22 |
| Narrow crowding | Stacked layout AC-19 |
| Body file size | D-CIH-012, AC-20 |

## 12. Canonical documentation

`care-item-evolution.md` and `care-item-view-ui.md` on `main` / this PR describe target UI **(pending implementation)**. This spec is the implementation source of truth.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-06 | Initial draft |
| 2026-10-06 | v2: chips, `careItemScreenTitle`, strip file, a11y ACs |
| 2026-10-06 | v2.1: stacked responsive; `CareItemPetContextTile`; chip priority; bare scaffolds in scope |
| 2026-10-06 | v2.2: **Finished** not Archived for `completed`; no Archived chip until API; D-CIH-014 uses 600 px predicate; module order = body code; AC-2 pet not found; stacked chip placement |
