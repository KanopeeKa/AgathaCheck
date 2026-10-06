---
title: Spec — Care Item context header and app bar title
owner: Product / Design
audience: both
status: draft
last_updated: 2026-10-06
tags: [pet_care, care_item, ux, accessibility, l10n]
---

# Spec — Care Item context header and app bar title

**Status:** draft — product decisions agreed 2026-10-06 (§9).  
**Surface:** Flutter Care Item detail (`/pet/:petId/events/:entryId`) — `CareItemDetailScreen`, `CareItemDetailBody`, related l10n EN/FR. No server change.

**Related**

| Document | Relationship |
|----------|----------------|
| [care-item-evolution.md](../features/care-item-evolution.md) | Amends § Care item view → Header (mobile order item 1) and mockup title rule |
| [care-item-view-ui.md](../../../design/care-item-view-ui.md) | Amends pet-context module decision |
| [terminology.md](../../../design/terminology.md) | Adds Care Item route app-bar labels |
| [care-item-bulk-scope-spec.md](./care-item-bulk-scope-spec.md) | Same route; no change to Needs attention semantics |

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

**The Care Item route uses a generic app bar title ("Care details"), a compact scrollable context strip (clickable pet tile + care name + category icon + lifecycle line when relevant), and no full-width pet module card.** Pet navigation matches **My Pets → pet detail**. Needs attention remains the first **module** on the warm canvas.

## 3. Locked decisions (2026-10-06)

| # | Decision |
|---|----------|
| D-CIH-001 | App bar title is **Care details** (EN) / **Détail du soin** (FR), not the care item name |
| D-CIH-002 | Care item **name** appears in the page **context strip** (max two lines, ellipsis) |
| D-CIH-003 | **Pet tile** is tappable; destination = same as tapping the pet on **My Pets** (`openPetDetail` / pet profile route for that `petId`) |
| D-CIH-004 | Reuse **dashboard pet tile** visual language via `UnifiedPetTile` / `PetCard` pattern **without** a status line (empty / omitted status) |
| D-CIH-005 | **Species chip** on the pet tile is **optional** — omit on this surface when space is tight; pet name + photo remain |
| D-CIH-006 | **Trailing category icon** beside the title block (`CareFamilyIcon.forEntry` or equivalent), not decorative-only |
| D-CIH-007 | **Lifecycle / state line** under or beside the title when the item is **paused**, **archived (closed)**, or **finished** — use existing copy tokens where possible |
| D-CIH-008 | Context strip is **not sticky**; it scrolls away to prioritise vertical real estate for modules |
| D-CIH-009 | Do **not** use "Care routine" as the app bar title (inaccurate for one-off / record flows) |
| D-CIH-010 | Screen reader label for the pet tile: **pet name** (and species only if shown visually); do **not** append "Opens profile" boilerplate |

## 4. Scope

### In scope

- `ExperienceShellScaffold` `screenTitle` on Care Item detail → l10n `careDetailsTitle` (proposed key)
- Replace `petModule` (`PetEventPetCard` in `CareItemModule`) with **context strip** widget
- Mobile column order: context strip → Needs attention → … (unchanged module order after strip)
- Wide layout: context strip **full width above** the two-column row; **remove** pet module from side column
- Widget tests, semantics-contract tests, and E2E selectors that assert old title or `PetEventPetCard` on this route
- Doc amendments listed in §12

### Out of scope

- Occurrence screen (`occurrence_screen.dart`) title/header
- Changes to agenda row copy or navigation into Care Item
- Notification payloads or in-app notification UI
- `PetEventPetCard` on **other** routes (unless a follow-up explicitly migrates them)

## 5. UX specification

### 5.1 App bar

| Element | Rule |
|---------|------|
| Title | Localized **Care details** / **Détail du soin** only |
| Actions | Unchanged: Edit, ⋯ menu (pause, archive, plan another date, etc.) |
| Back | Unchanged shell back behaviour |

The care item name must **not** appear in the app bar on this route after implementation.

### 5.2 Context strip (new)

**Layout (mobile and wide)**

```
┌─────────────────────────────────────────────────────────┐
│  [ Pet tile ]   Care item name (1–2 lines)      [icon] │
│                 Optional state line (paused/…)           │
└─────────────────────────────────────────────────────────┘
```

| Part | Rule |
|------|------|
| Container | **Not** a `CareItemModule` — sits on the **warm page canvas** with horizontal padding consistent with `CareItemDetailCanvas` (16 logical px default) |
| Pet tile | Compact fixed width (target **72–96** logical px wide; height **≥ 48** touch target). Photo + **one-line** pet name truncation. **No** status line. **InkWell** / `UnifiedPetTile` tap → `openPetDetail(context, pet.id)` |
| Title | `titleLarge` or equivalent; **max 2 lines** then ellipsis; left-aligned in remaining horizontal space |
| Category icon | Trailing in the title row (`CareFamilyIcon.forEntry(entry, showChip: false)` or successor); ≥ 48×48 tap target if tappable, else decorative with accessible name from family/category |
| State line | When `entry.isPaused`, closed/archived, or series finished: show one short line using existing status copy (e.g. paused until, Finished · date, Archived). Muted typography. Omit when item is active/open with no special lifecycle state |
| Spacing below | **16** logical px gap before first module (Needs attention) |

**Scrolling:** The strip is the first child of the scrollable body; it **scrolls off** with content (D-CIH-008).

### 5.3 Wide layout (≥ 900 logical px) — recommendation

Follow common **detail-page** pattern on web: **one entity header spanning the content width**, then asymmetric columns.

| Region | Content |
|--------|---------|
| Full width (above columns) | Context strip only |
| Main column (flex 3) | Needs attention, Established (if any), History |
| Side column (flex 2) | Schedule, Absence, Details — **no pet module** |

Rationale: avoids duplicating pet context in the sidebar, keeps the same mental model as mobile, and matches patterns users know from issue trackers and admin detail views (title row full width, fields in columns below).

### 5.4 Module order (unchanged after strip)

Mobile: strip → Needs attention → Absence (when attention) / Schedule block → Details → History.  
Wide: strip → two-column split per §5.3; inner module order unchanged from current `CareItemDetailBody`.

## 6. Copy and l10n

| Key (proposed) | EN | FR |
|----------------|----|----|
| `careDetailsTitle` | Care details | Détail du soin |

Add to `app_en.arb` / `app_fr.arb`; run code generation. Do not repurpose `allCareTitle` (pet-scoped list) or `allCare` (global queue).

Internal docs may keep **Care Item**; user-visible route title uses **Care details** only.

## 7. Accessibility

| Requirement | Detail |
|-------------|--------|
| Context strip | `Semantics(header: true)` on the strip or title block so VoiceOver/TalkBack announce the care name as a heading after the generic app bar |
| Pet tile | `Semantics(identifier: 'care_item_pet_tile')` (or stable successor); label = pet name (+ species if shown) |
| Touch targets | Pet tile and app bar actions ≥ **48×48** logical px |
| Colour | State line and icons follow existing semantic tokens; status not colour-alone |
| Focus | Visible focus ring on pet tile when focused (web keyboard) |

## 8. Acceptance criteria

### App bar and copy

- **AC-1:** With care item name "Heart tablet", the app bar shows **Care details** (EN) or **Détail du soin** (FR), not "Heart tablet".
- **AC-2:** `careDetailsTitle` exists in EN and FR ARB files and is wired to `CareItemDetailScreen` (and loading/error shells on the same route use the same title, not `allCareTitle(pet.name)` except where route is genuinely wrong — loading state should still say Care details).

### Context strip content

- **AC-3:** "Heart tablet" (or current entry name) appears in the context strip, not in the app bar.
- **AC-4:** Long names wrap to a **second line**; a third line is truncated with ellipsis.
- **AC-5:** A **category icon** for the entry family is visible in the strip (same semantics as info section icon).
- **AC-6:** When the entry is **paused**, a muted state line reflects paused copy (existing l10n).
- **AC-7:** When the entry is **closed/archived** or **finished**, a muted state line reflects finished/archived copy.
- **AC-8:** When the entry is active with no lifecycle state, no redundant state line is shown.

### Pet tile behaviour

- **AC-9:** Tapping the pet tile navigates to the **same destination** as tapping that pet on **My Pets** (pet profile for `petId`).
- **AC-10:** Pet tile does **not** show dashboard status (overdue counts, "All set", etc.).
- **AC-11:** `PetEventPetCard` is **not** rendered on the Care Item detail body for this route.

### Layout and modules

- **AC-12:** The context strip is **not** wrapped in `CareItemModule` (no white module card around pet + title).
- **AC-13:** **Needs attention** remains the first `CareItemModule` (or equivalent module surface) below the strip on mobile.
- **AC-14:** At viewport width **≥ 900**, the context strip spans **full content width above** the two-column layout; the side column does **not** include a pet module.
- **AC-15:** The context strip scrolls away when the user scrolls down (not pinned / not `SliverPersistentHeader` pinned).

### Regression

- **AC-16:** Edit, ⋯ menu, Needs attention actions, and deep link route `/pet/:petId/events/:entryId` behave as before.
- **AC-17:** No new user-visible string contains "occurrence".

## 9. Verification checklist (implementation PR)

| Layer | Action |
|-------|--------|
| Widget | Update `care_item_detail_body_test.dart` — strip present, two-column wide layout without side pet module, semantics ids |
| Widget | New or updated test for app bar title via `CareItemDetailScreen` pump (mirrored path under `test/features/care_item/`) |
| Semantics contract | `care_item_pet_tile` (+ header) if referenced from Playwright |
| Playwright | `care-item.page.ts` and BDD scenarios that assert entry name in app bar → assert **Care details** + name in strip |
| l10n | EN/FR ARB + generated localizations |
| Docs | §12 amendments merged with this spec |
| Manual | Smoke on mobile width + wide web: tap pet tile → profile; scroll → strip leaves viewport |

## 10. Open follow-ups (not blocking this spec)

| Topic | Notes |
|-------|--------|
| Occurrence screen titles | Separate requirement; link from occurrence header to Care Item remains |
| Agenda → Care Item entry paths | Separate requirement (multi-pet context) |
| Notifications | Separate notification review |
| `PetEventPetCard` on other health event screens | Optional consolidation later |

## 11. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Generic app bar weakens wayfinding for long med names | Prominent two-line title + header semantics in strip (AC-3, AC-4, §7) |
| Compact tile too small for touch | Enforce min 48×48 tap target on tile (§7) |
| Wide layout regression | AC-14 + existing `care_item_detail_two_column` key test updated |

## 12. Canonical doc amendments (same programme as implementation)

When implementing, update:

1. **care-item-evolution.md** — § Care item view → Header: replace bullet with pointer to this spec (generic app bar + context strip).
2. **care-item-view-ui.md** — Module map item 1 and web table: context strip on canvas; wide = full-width strip above columns.
3. **terminology.md** — New row under Pet Care workspace labels for Care Item detail app bar.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-10-06 | Initial draft from product UX review |
