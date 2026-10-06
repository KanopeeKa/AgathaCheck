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
**Surface:** Flutter Care Item detail (`/pet/:petId/events/:entryId`) — `CareItemDetailScreen`, `CareItemDetailBody`, new `care_item_context_strip.dart`, new `care_item_pet_context_tile.dart`, related l10n EN/FR. No server change.

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
| D-CIH-004 | **`CareItemPetContextTile`** in `care_item_pet_context_tile.dart` — reuses **photo helper only** (`buildPetPhotoOrPlaceholder` / existing pet photo widgets). **Do not** modify `UnifiedPetTile`, `PetCard`, or `PetTileDimensions` |
| D-CIH-005 | Species on pet chip **optional**; pet **name always visible** to sighted users (no avatar-only layout) |
| D-CIH-006 | **Category icon** — visual only; family name in care-name **header** semantics label only |
| D-CIH-007 | **Strip:** at most **one** status chip (no dates, no actions). **Needs attention** (and evolution-assigned modules) own paused/finished/archived **copy and actions** |
| D-CIH-008 | Strip **not sticky**; scrolls away |
| D-CIH-009 | App bar title is **not** "Care routine" |
| D-CIH-010 | Pet chip semantics: **button**, label = pet name (+ species if shown); no "Opens profile" suffix |
| D-CIH-011 | **`Semantics(header: true)` on care name `Text` only** — not on the whole strip |
| D-CIH-012 | **`CareItemContextStrip`** in `care_item_context_strip.dart`; keep `care_item_detail_body.dart` under 500 lines |
| D-CIH-013 | **Status chip priority** (at most one): **Archived > Finished > Paused** — derivation §5.2.2 |
| D-CIH-014 | **Wide shell:** when `ExperienceShellScaffold` shows content-header title (`usesDesktopContentHeader`), strip care name uses **`theme.textTheme.titleMedium` with `fontWeight: FontWeight.w700`**; mobile strip care name uses **`titleLarge`** |

## 4. Scope

### In scope

- **`careItemScreenTitle`** on every state of this route (AC-2), including **migrating bare `Scaffold` shells** (pets loading/error before pet resolved) to `ExperienceShellScaffold` + route title in `care_item_detail_screen.dart`
- `CareItemContextStrip` + `CareItemPetContextTile` (new files)
- Replace `petModule` with strip; wide layout per §5.3
- Status chip logic §5.2.2; l10n §6
- Widget tests, semantics contract, Playwright audit §9
- Doc cross-links (this spec is canonical for implementation)

### Out of scope

- Occurrence screen, agenda entry paths, notifications
- `PetEventPetCard` on other routes
- Any change to dashboard / My Pets `UnifiedPetTile` behaviour (AC-21)

## 5. UX specification

### 5.1 App bar

| Element | Rule |
|---------|------|
| Title | `l.careItemScreenTitle` only |
| Actions | Unchanged (Edit, ⋯) |
| Back | Unchanged |

Care item name **not** in app bar after implementation.

**Wide / leading-nav:** Shell content chrome shows `screenTitle` as **`titleLarge` w700**. Strip care name uses **D-CIH-014** (`titleMedium` w700) so headings do not duplicate at the same scale.

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
| Care name | Mobile: `titleLarge`, max 2 lines, ellipsis. Wide content header: `titleMedium` w700 (D-CIH-014) |
| Category icon | Trailing on care-name row; non-interactive |
| Status chip | §5.2.2; muted chip below name row or inline per layout |
| Gap before first module | **16 px** |

#### 5.2.1 Responsive stacked layout (mandatory fallback)

When viewport width **≤ 360** logical px **or** text scale **≥ 1.3**, use **stacked** strip (single rule — no avatar-only pet tile):

**Row 1:** Pet chip — 40 px avatar + pet name (≥ 48 px tall), full width of strip, tappable.

**Row 2:** Care name (up to 2 lines) with category icon **trailing** on the same row, **or** icon on a third line directly under the care name if the row would overflow.

Pet name remains **visible** for sighted users in all breakpoints.

#### 5.2.2 Status chip — source and priority

Show **at most one** chip. Priority: **Archived > Finished > Paused**. If multiple predicates match, show only the highest-priority chip.

| Chip | Show when | l10n |
|------|-----------|------|
| **Archived** | `entry.status == 'completed'` (user **Archive** / `closeEvent` — D-CIE-018) | `careItemStatusArchived` |
| **Finished** | `isHealthEntrySeriesClosed(entry)` is true **and** `entry.status != 'completed'` (e.g. one-off completed via `entry.isCompleted`, or `repeatEndDate` before today per `isHealthEntrySeriesClosedAt`) | `careItemStatusFinished` |
| **Paused** | `entry.isPaused` **and** neither Archived nor Finished chip applies | **`careItemPausedStatus`** (existing) |

**Open item (implementation):** If product later splits `completed` into distinct archived vs finished wire values, update this table in a small spec amend; until then the rules above are normative for the client.

When **Active** (no chip predicates): **no** status chip.

### 5.3 Wide layout (≥ 900 logical px)

Full-width strip above two-column body; **no** pet module in side column (unchanged from v2).

### 5.4 Module order (unchanged after strip)

Strip → Needs attention → Agatha (when present) → absence/schedule block → observation/weight slot (when applicable) → Details → History.

## 6. Copy and l10n

| Key | EN | FR | Use |
|-----|----|----|-----|
| `careItemScreenTitle` | Care details | Détail du soin | App bar |
| `careItemPausedStatus` | Paused | (existing FR) | Strip chip — **reuse; do not add** `careItemStatusPaused` |
| `careItemStatusArchived` | Archived | (TBD in ARB) | Strip chip |
| `careItemStatusFinished` | Finished | Fini | Strip chip |

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
- **AC-2:** **Every** state of `/pet/:petId/events/:entryId` shows `careItemScreenTitle` in `ExperienceShellScaffold`, including pets **loading** and **error** (migrate off bare `Scaffold`).

### Context strip

- **AC-3:** Item name in strip, not app bar.
- **AC-4:** Max two lines for care name, then ellipsis.
- **AC-5:** Category icon visible; not separately focusable.
- **AC-6:** Paused → chip text from **`careItemPausedStatus`** only; dates in Needs attention.
- **AC-7:** Archived / Finished chips per §5.2.2; Restore / full lifecycle copy only in Needs attention.
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

- **AC-19:** At 320 px width **or** text scale ≥ 1.3: **stacked** layout §5.2.1; **pet name visible**; no horizontal overflow.

### Typography (wide)

- **AC-22:** When `usesDesktopContentHeader` is true, strip care name uses **`titleMedium` w700**; when false, **`titleLarge`**.

### Regression and isolation

- **AC-16:** Edit, ⋯, Needs attention, route URL unchanged.
- **AC-17:** No new user-visible "occurrence".
- **AC-20:** Strip in `care_item_context_strip.dart`.
- **AC-21:** **My Pets / dashboard** `UnifiedPetTile` / `PetCard` widgets and golden/widget tests **unchanged** (no shared-tile refactor).

### Chip logic

- **AC-23:** When `status == 'completed'`, chip is **Archived** even if `isHealthEntrySeriesClosed` is also true. When series closed and status not `completed`, chip is **Finished**. When paused and no higher chip, **Paused**.

## 9. Verification checklist (implementation PR)

| Layer | Action |
|-------|--------|
| Widget | Strip, chip priority, stacked breakpoint, wide typography |
| Widget | `CareItemDetailScreen` — AC-2 including former bare scaffolds |
| Widget | Regression: `pet_card_test` / dashboard tile tests untouched |
| Semantics | `care_item_pet_tile` + header |
| Playwright | Audit `care-item.page.ts` for entry-name-in-title assumptions; add route title + tile identifier as needed |
| l10n | Keys §6 |
| Manual | Stacked layout 320 px; wide `titleMedium`; pet tap returnTo |

## 10. Open follow-ups

| Topic | Notes |
|-------|--------|
| Occurrence screen | Separate requirement |
| Wire-level Archived vs Finished | If `completed` overload grows, amend §5.2.2 |
| Agenda / notifications | Separate |

## 11. Risks

| Risk | Mitigation |
|------|------------|
| Generic tab title | Strip title + AC-3/4/18 |
| `completed` = Archived only | §5.2.2 + AC-23; open item if server adds distinction |
| Twin large headings on wide | D-CIH-014, AC-22 |
| Narrow crowding | Stacked layout AC-19 |
| Body file size | D-CIH-012, AC-20 |

## 12. Canonical documentation

`care-item-evolution.md`, `care-item-view-ui.md`, and `terminology.md` on `main` describe target UI **(pending implementation)**. This spec is the implementation source of truth; remove pending notes when Flutter ships.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-06 | Initial draft |
| 2026-10-06 | v2: chips, `careItemScreenTitle`, strip file, a11y ACs |
| 2026-10-06 | v2.1: stacked responsive (no avatar-only); `CareItemPetContextTile` only; chip derivation + priority; `careItemPausedStatus`; bare scaffold migration in scope; `titleMedium` w700 wide; AC-21–23 |
