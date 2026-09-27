---
title: Care Item view — UI modules
owner: Design Team
audience: both
status: active
last_updated: 2026-09-27
tags: [design, pet-care, care-item]
---

# Care Item view — UI modules

Canonical **visual** spec for the Care Item detail route (`/pet/:petId/events/:entryId`). Product copy and field rules remain in [care-item-evolution.md](../domains/pet_care/features/care-item-evolution.md).

## Intent

Operational **care desk** segmentation: warm page canvas, white module cards, clear action hierarchy. Calm — no decorative rainbow; severity uses shared semantic tokens + text.

## Decisions (2026-09-27)

| Topic | Decision |
|-------|----------|
| Relief | **Border-first** white modules on warm canvas; optional subtle shadow on web only (default off in v1) |
| Pet context | **Keep pet module** at top on mobile; compact chip in app bar on wide layouts (phase `web-layout`) |
| Icons | **Section headers + stat cells** only; not every metadata row |
| Absence | **`CareAttentionCallout`** tier when slice needs attention; hide section when no upcoming absence (spec open item) |
| Copy | No “View …” title; no “Current occurrence” (D-CIE-001) |

## Tokens (semantic)

| Role | Implementation |
|------|----------------|
| Page canvas | `AppColorTokens.petCareCollection` / `CareSurfaceTokens.collectionBackground()` |
| Module surface | `CareSurfaceTokens.moduleBackground()` (`neutral-50`) |
| Module border | `CareSurfaceTokens.moduleBorder()` |
| Module radius | `CareSurfaceTokens.collectionRadius` (16) |
| Hero inner radius | `CareSurfaceTokens.actionRadius` (12) |

Document hex values only in [`tokens.md`](./tokens.md) when promoted globally; Care Item v1 uses existing care-surface tokens.

## Module map (mobile order)

1. **Pet context** — existing `PetEventPetCard` inside `CareItemModule` (compact).
2. **Needs attention (hero)** — status pill + display date (`headlineSmall`) + care name secondary + **one** `FilledButton` + outlined secondaries in a row; occurrence rows inset inside module.
3. **Absence** — module or callout; resolution actions inside module body.
4. **Schedule** — header row with **Edit schedule** trailing; body = stat grid (Frequency · Type · Reminder) + prose lines (next date, flexibility).
5. **Details** — definition-list rows; **no duplicate recurrence** (schedule owns rhythm).
6. **History** — inset list (`CareCollectionInsetList` pattern) + **See full history** in module footer.

## Web (≥ `kCareItemTwoColumnBreakpoint`)

| Main column | Side column |
|-------------|-------------|
| Needs attention, Agatha (when present), History | Schedule, Absence, Details |

Pet context: side column top or header chip — implementation in `web-layout` phase.

## Components (Flutter)

| Widget | Path |
|--------|------|
| `CareItemModule` | `pet_care/.../care_surface/care_item_module.dart` |
| `CareItemSectionHeader` | `care_item_section_header.dart` |
| `CareItemStatCell` / `CareItemStatRow` | `care_item_stat_row.dart` |
| `CareItemDetailRow` | `care_item_detail_row.dart` |
| `CareItemStatusPill` | `care_item_status_pill.dart` |
| `CareItemDetailCanvas` | `care_item_detail_canvas.dart` |

## Acceptance (implementation)

- [ ] Modules use tokens; no ad-hoc `surfaceContainer*` on section roots
- [ ] Needs attention visually dominant; single primary CTA
- [ ] Overdue pill + text (D-CIE-006)
- [ ] Details omit repeated `formatRecurrenceSummary`
- [ ] Semantics headers preserved; actions ≥48dp
- [ ] Widget tests for new primitives

## Phased delivery

Execute-plan `care-item-view-ui`: design → primitives → needs-attention → schedule-absence → details-history → web-layout → header-wayfinding → integration-main.
