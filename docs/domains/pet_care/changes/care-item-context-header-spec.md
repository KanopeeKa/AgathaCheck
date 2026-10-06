---
title: Spec — Care Item context header and app bar title
owner: Product / Design
audience: both
status: agreed
last_updated: 2026-10-06
tags: [pet_care, care_item, ux, accessibility, l10n]
---

# Spec — Care Item context header and app bar title

**Status:** **agreed** — product decisions 2026-10-06; **UI pending implementation** (canonical docs on `main` describe target behaviour; Flutter route still uses item name in app bar and `PetEventPetCard` until implementation PR).  
**Surface:** Flutter Care Item detail (`/pet/:petId/events/:entryId`) — `CareItemDetailScreen`, `CareItemDetailBody`, new `care_item_context_strip.dart`, related l10n EN/FR. No server change.

**Related**

| Document | Relationship |
|----------|----------------|
| [care-item-evolution.md](../features/care-item-evolution.md) | Amends § Care item view → Header (mobile order item 1) and mockup title rule — **(pending implementation)** |
| [care-item-view-ui.md](../../../design/care-item-view-ui.md) | Amends pet-context module decision — **(pending implementation)** |
| [terminology.md](../../../design/terminology.md) | Care Item route app-bar labels |
| [care-item-bulk-scope-spec.md](./care-item-bulk-scope-spec.md) | Same route; no change to Needs attention **actions** or dates |

**Explicitly out of scope (separate requirements)**

- Occurrence screen app bar and header rework
- Create/Edit care form titles
- Notification deep-link titles
- Multi-pet / dashboard entry-path wayfinding review
- Pet tile destination when opened from contexts other than Care Item (unchanged elsewhere)

## 1. Problem

On the Care Item detail route today:

1. The **app bar title** is the care item name (e.g. "Heart tablet"). That duplicates the identity users already chose from the agenda and competes with the **Needs attention** hero for attention.
2. The **pet block** is a large module (`PetEventPetCard` inside `CareItemModule`) with limited information (photo, name, species) and **no navigation** to the pet profile, despite the functional spec requiring a tappable pet affordance.
3. On **wide layouts** (≥ `kCareItemTwoColumnBreakpoint`, 900 logical px), the pet module sits in the **side column**, separating pet context from the action column and consuming module chrome without adding operational value.

Users need a calmer hierarchy: **what needs doing now** first, with **who** (pet) and **what** (named care) as compact, scannable context — not a second headline in the system chrome.

## 2. Outcome

**The Care Item route uses a generic app bar title ("Care details"), a compact scrollable context strip (clickable pet context tile + care name + non-interactive category icon + optional short status chip), and no full-width pet module card.** Pet navigation uses **`openPetDetail`** (same as My Pets). **Needs attention** (and modules assigned by [care-item-evolution.md](../features/care-item-evolution.md) for paused/closed care) remain the place for **lifecycle dates and actions**. The strip may show a **short status chip only** so context survives after scroll (D-CIH-007).

## 3. Locked decisions

| # | Decision |
|---|----------|
| D-CIH-001 | App bar title is **Care details** (EN) / **Détail du soin** (FR), not the care item name; l10n key **`careItemScreenTitle`** (not `careItemDetailsTitle`, which is the Details module header) |
| D-CIH-002 | Care item **name** appears in the page **context strip** (max two lines, ellipsis) |
| D-CIH-003 | **Pet context tile** is tappable via **`openPetDetail(context, petId)`** — pushes `/pet/:id` with `returnTo` = current shell location so **Back** from pet profile returns to this Care Item |
| D-CIH-004 | **Do not** use stock `UnifiedPetTile` without a dedicated **care-item-strip** preset: default tile min width 120 px, height ≥140 px, and `statusLine: null` falls back to **"All set"**. Implement **`CareItemPetContextTile`** (or `UnifiedPetTile` with `PetTileContext.careItemStrip`: hidden status, compact dimensions, explicit `semanticsLabel`) aligned visually with dashboard tiles |
| D-CIH-005 | **Species chip** on the pet tile is **optional** — omit when space is tight; pet name + photo remain |
| D-CIH-006 | **Trailing category icon** (`CareFamilyIcon.forEntry`, `showChip: false`) — **visual only**, non-interactive; category name folded into the **care name header** semantics label (Details module still exposes family; no second focus stop) |
| D-CIH-007 | **Lifecycle:** **Needs attention** (and evolution-assigned modules) own **dates and actions** (Paused since …, Resume, Finished · date, Archived + Restore). Strip shows **short status chip only** when paused, closed/archived, or series finished — **no dates, no buttons** (e.g. Paused, Archived, Finished). Omit chip when item is active with no special lifecycle state |
| D-CIH-008 | Context strip is **not sticky**; it scrolls away to prioritise vertical real estate for modules |
| D-CIH-009 | Do **not** use "Care routine" as the app bar title (inaccurate for one-off / record flows) |
| D-CIH-010 | Pet tile semantics: **button**, label = **pet name** (+ species only if shown); **no** "Opens profile" suffix |
| D-CIH-011 | Care name semantics: **`Semantics(header: true)` on the title text only**, not on the whole strip (so the pet button is not swallowed into the heading) |
| D-CIH-012 | Extract strip to **`care_item_context_strip.dart`** — `care_item_detail_body.dart` is near the 500-line modularity limit |

## 4. Scope

### In scope

- `ExperienceShellScaffold` `screenTitle` → `l.careItemScreenTitle` on **every** shell-backed state of this route (see AC-2)
- New **`CareItemContextStrip`** in `care_item_context_strip.dart`; body composes it only
- Replace `petModule` (`PetEventPetCard` in `CareItemModule`) with the strip
- Mobile column order: strip → Needs attention → … (unchanged module order after strip; Agatha and observation slot unchanged — §5.4)
- Wide layout: context strip **full width above** the two-column row; **remove** pet module from side column
- Widget tests, semantics-contract tests, Playwright audit (§9)
- Status chip l10n keys (§6)

### Out of scope

- Occurrence screen title/header
- Agenda navigation into Care Item
- Notifications
- `PetEventPetCard` on other routes

## 5. UX specification

### 5.1 App bar

| Element | Rule |
|---------|------|
| Title | `careItemScreenTitle` — **Care details** / **Détail du soin** only |
| Actions | Unchanged: Edit, ⋯ menu |
| Back | Unchanged shell back behaviour |

The care item name must **not** appear in the app bar after implementation.

**Wide / leading-nav shell:** `ExperienceShellScaffold` may show `screenTitle` as **`titleLarge` in the content chrome**. The strip care name must use **one step smaller type** than on mobile (e.g. `titleMedium` / `headlineSmall`) so "Care details" and the item name do not compete as twin `titleLarge` headlines.

**Browser tab / document title:** If the shell maps `screenTitle` to the page title, tabs may all read "Care details" — acceptable for v1; notification deep links are out of scope.

### 5.2 Context strip

**Layout (mobile)**

```
┌─────────────────────────────────────────────────────────┐
│  [ Pet tile ]   Care item name (1–2 lines)      [icon] │
│                 [ Paused | Archived | Finished ]  (chip) │
└─────────────────────────────────────────────────────────┘
```

| Part | Rule |
|------|------|
| Container | **Not** `CareItemModule`; first child inside the body's existing scroll view — **no extra horizontal padding** beyond the scroll view's existing inset (typically 16 px all round) |
| Pet tile | **`CareItemPetContextTile`** (or approved compact preset): target width **88–112** logical px, height **56–80**, touch target **≥ 48×48**. Photo + **one-line** pet name (or avatar-only at narrow breakpoint — §5.2.1). **No** dashboard status. Tap → `openPetDetail(context, pet.id)` |
| Title | Mobile: `titleLarge`, max **2 lines**, ellipsis. Wide (content header active): one step smaller per §5.1 |
| Category icon | Trailing; **non-interactive**; excluded from separate semantics; family in header label |
| Status chip | Optional **muted chip** per D-CIH-007 only; keys in §6 |
| Spacing below | **16** logical px before first module |

**Scrolling:** Strip scrolls off with content (D-CIH-008).

#### 5.2.1 Responsive (narrow / large text)

At viewport width **≤ 360** logical px **or** text scale **≥ 1.3**:

- Category icon moves **below** the title row **or** is hidden; **no horizontal overflow**.
- Pet tile may collapse to **avatar-only** (photo still ≥ 48×48 tap target); pet name remains on the button semantics label.

### 5.3 Wide layout (≥ 900 logical px)

| Region | Content |
|--------|---------|
| Full width (above columns) | Context strip only |
| Main column (flex 3) | Needs attention, Established (if any), History |
| Side column (flex 2) | Schedule, Absence, Details — **no pet module** |

### 5.4 Module order (unchanged after strip)

Same as current `CareItemDetailBody`: strip → Needs attention → (Agatha when present) → absence/schedule block → Details (incl. observation/weight slot when applicable) → History. Wide: strip → two-column split per §5.3.

**Authority for lifecycle copy and actions:** [care-item-evolution.md](../features/care-item-evolution.md) § Needs attention and paused rows — not duplicated in the strip beyond D-CIH-007 chips.

## 6. Copy and l10n

| Key | EN | FR | Use |
|-----|----|----|-----|
| `careItemScreenTitle` | Care details | Détail du soin | App bar / shell title |
| `careItemStatusPaused` | Paused | (TBD — align with `careItemPausedStatus`) | Strip chip only |
| `careItemStatusArchived` | Archived | (TBD) | Strip chip only |
| `careItemStatusFinished` | Finished | Fini | Strip chip only |

Add EN/FR to `app_en.arb` / `app_fr.arb`. Do **not** reuse `careItemDetailsTitle` ("Details" module). Do not repurpose `allCareTitle` / `allCare`.

Long lifecycle strings (`careItemPausedSince`, `careItemPausedUntil`, etc.) stay in **Needs attention** / date modules only.

## 7. Accessibility

| Requirement | Detail |
|-------------|--------|
| Care name | `Semantics(header: true)` on **title `Text` only**; label includes care name + care family/category (D-CIH-011, D-CIH-006) |
| Pet tile | `Semantics(identifier: 'care_item_pet_tile')`; **button**; label = pet name (+ species if shown) |
| Category icon | Decorative; no separate focusable node |
| Touch targets | Pet tile ≥ **48×48**; app bar actions unchanged |
| Colour | Chip and icons use semantic tokens; status not colour-alone |

## 8. Acceptance criteria

### App bar and route title

- **AC-1:** Loaded state: app bar shows **Care details** / **Détail du soin**, not the item name.
- **AC-2:** **Every** state of `/pet/:petId/events/:entryId` that uses `ExperienceShellScaffold` (pets loading/error/not found, entry loading/error/not found, loaded) uses `careItemScreenTitle`. Bare `Scaffold` shells without a title are **migrated** to the shell + route title or listed as explicit exceptions in the implementation PR (prefer migrate).

### Context strip content

- **AC-3:** Item name appears in the strip, not the app bar.
- **AC-4:** Long names: max **two lines**, then ellipsis.
- **AC-5:** Category icon visible; **not** separately focusable.
- **AC-6:** When **paused**, strip shows **Paused** chip only (no dates); paused dates/actions remain in Needs attention / date module.
- **AC-7:** When **closed/archived** or **series finished**, strip shows **Archived** or **Finished** chip only; full copy and Restore/Resume stay in Needs attention.
- **AC-8:** Active item: **no** status chip.

### Pet tile behaviour

- **AC-9:** Tap uses `openPetDetail(context, petId)`; Back from pet profile returns to this Care Item (`returnTo`). Same for pets from `allPetsIncludingOrgProvider` (owned, shared, fostered, passed-away sections) — no Care-Item-specific branch unless product blocks a class of pet (none today).
- **AC-10:** No dashboard status line ("All set", overdue counts, etc.).
- **AC-11:** No `PetEventPetCard` on this route's body.

### Layout and modules

- **AC-12:** Strip not in `CareItemModule`.
- **AC-13:** Needs attention is first module below strip on mobile.
- **AC-14:** Wide: strip full width above columns; no side pet module.
- **AC-15:** Strip scrolls away (not pinned).

### Accessibility

- **AC-18:** Pet tile announced as **button** with pet name; care name announced as **heading**; not one merged heading over both.

### Responsive

- **AC-19:** At **320** logical px width and text scale **≥ 1.3**, no horizontal overflow; icon/tile layout follows §5.2.1.

### Regression

- **AC-16:** Edit, ⋯, Needs attention actions, route URL unchanged.
- **AC-17:** No new user-visible "occurrence" string.

### Implementation structure

- **AC-20:** `CareItemContextStrip` (or equivalent) lives in **`care_item_context_strip.dart`**; `care_item_detail_body.dart` stays under modularity limit.

## 9. Verification checklist (implementation PR)

| Layer | Action |
|-------|--------|
| Widget | `care_item_detail_body_test.dart` — strip, wide layout without side pet module |
| Widget | `care_item_context_strip_test.dart` (or screen test) — chips, breakpoints, semantics |
| Widget | `CareItemDetailScreen` — AC-2 shell title matrix |
| Semantics contract | `care_item_pet_tile` + care name header if Playwright depends on them |
| Playwright | **Audit** `care-item.page.ts` / BDD for entry-name-in-app-bar assumptions; add checks for route title + strip semantics/tile key as needed (today page object does not assert app bar item name) |
| l10n | `careItemScreenTitle` + chip keys EN/FR |
| Manual | Mobile + wide: pet tap + returnTo; scroll strip away; 320 px / large text |

## 10. Open follow-ups

| Topic | Notes |
|-------|--------|
| Occurrence screen | Separate requirement |
| Agenda entry paths | Separate requirement |
| Notifications | Separate review |
| `PetEventPetCard` elsewhere | Optional consolidation |

## 11. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Generic app bar / tab title | Prominent strip title; AC-3, AC-4, AC-18 |
| Wrong tile widget → "All set" | D-CIH-004, AC-10 |
| Duplicate lifecycle UI | D-CIH-007, AC-6, AC-7 |
| Twin `titleLarge` on wide | §5.1 typography rule |
| Narrow layout crowding | AC-19, §5.2.1 |
| `care_item_detail_body.dart` size | D-CIH-012, AC-20 |

## 12. Canonical documentation

**Already amended on `main` (2026-10-06):** `care-item-evolution.md`, `care-item-view-ui.md`, `terminology.md` describe **target** UI marked **(pending implementation)** where noted.

**Implementation PR must:** ship Flutter behaviour matching this spec and remove "(pending implementation)" notes when done.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-06 | Initial draft from product UX review |
| 2026-10-06 | v2: review amendments — chips vs lifecycle, `careItemScreenTitle`, pet tile widget, AC-2/9/18/19/20, wide typography, semantics, docs status |
