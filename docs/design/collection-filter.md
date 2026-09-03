---
title: Collection filtering (canonical pattern)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-03
tags: [design, ux, filtering]
---

# Collection filtering — canonical pattern

Progressive-disclosure filtering for list and collection screens. Replaces always-visible chip clouds with compact category controls, removable active-filter chips, and a structured mobile sheet.

**Implementation:** `flutter_app/lib/core/widgets/collection_filter/`  
**Locked decisions:** execute-plan `collection-filter-canonical-f8a2` (2026-09-03)

---

## 1. Problem

Chip rows that expose every filter value at once are hard to scan, do not scale with pets/orgs/categories, and dominate collection screens on mobile and tablet.

## 2. Why it matters

Events and similar screens are operational workspaces. Users need powerful filtering without a filter configuration form above the list.

## 3. UX impact

| Before | After |
|--------|-------|
| Multi-row horizontal chip scroll | Compact toolbar or single Filters control |
| “All” repeated per dimension | Default = no chip; values in menus/sheet |
| Filter + sort conflated | Filters only; no Sort in this pattern unless product adds it separately |

## 4. Accessibility impact

- Toolbar dimension triggers are `OutlinedButton` with semantics labels (≥48×48).
- Mobile sheet uses standard list tiles with checkbox/radio controls.
- Active filters expose removable `InputChip` with delete affordance.
- Live filtering avoids trapping users in a staged “Apply” state.

## 5. System impact

One shared widget set for Pet Care Events, org Events, vet list, org filters, and secondary org-pet refinements. Screen-specific **predicate logic stays in feature code**; UI maps to `CollectionFilterDimension` specs.

## 6. Proposed fix (canonical rule)

**Rule:** Collection filters use progressive disclosure.

1. **Categories visible** — dimension labels as toolbar buttons or sheet sections.
2. **Values on demand** — checkbox multi-select (OR within dimension) or radio when `multiSelect: false`.
3. **Active selections visible** — removable chips; count badge on Filters / dimension when active.
4. **Reset** — clear per dimension in menu; clear all in mobile sheet header.
5. **No default chips** — empty selection set = “all” for that dimension.

## 7. Reusable components

| Widget | Role |
|--------|------|
| `CollectionFilterBar` | Responsive entry: toolbar (≥600 logical px) or mobile trigger + active chips |
| `CollectionFilterToolbar` | Primary dimension menus + More filters overflow |
| `FilterDimensionMenuButton` | Single dimension `MenuAnchor` with checkboxes |
| `CollectionFilterSheet` | Mobile bottom sheet, live filter, Done dismisses only |
| `ActiveFilterChipsRow` | Removable active filter summary |
| `CollectionFilterController` | Pure selection helpers (toggle, clear, active chips) |

### Responsive model

| Viewport | Chrome |
|----------|--------|
| **Wide** | `[ Pet ] [ Type ] [ Status ] [ More filters ]` + active chips row |
| **Tablet** | Same; wrap secondary dimensions into More when tight |
| **Mobile** | `[ Filters n ]` + active chips row |

### Events mapping (Phases 2–3)

| Dimension | Notes |
|-----------|-------|
| Pet | All pets + individual pets; cohort (My/Foster) under More |
| Type | Medication, preventive, vet visit, other — multi OR |
| Status | Open, closed, due/overdue — multi OR |
| More | Recurrence, skipped (hide), org context where relevant |

**Skipped:** active chip only when hidden (`showSkipped: false`).

## 8. Implementation notes

- Adapters in feature code translate `ManageEventsFilters` ↔ `CollectionFilterSelections`.
- Preserve existing match predicates; UI-only refactor unless bug found.
- Stable keys: `filter_dimension_trigger_<id>`, `collection_filter_mobile_trigger`, `active_filter_<dimension>_<choice>`.
- Deprecate `ManageEventsFilterBar`, `GuardianGlobalEventsFilterBar` after migration.

## 9. Acceptance checklist

- [ ] Theme tokens / `Theme.of(context)` — no ad-hoc palette
- [ ] Focus visible; touch ≥48dp on triggers
- [ ] l10n for More filters, Clear all, Filters {count}
- [ ] Empty active state: toolbar only, no chip row
- [ ] Live filter updates list immediately
- [ ] Multi-select OR semantics preserved
- [ ] Org `/o/events` uses same bar as `/pc/events` (Phase 3)
- [ ] `pre-push-changed.sh` / widget tests green

---

## Screens — migrate vs keep

**Migrate (collection filters):** `/pc/events`, per-pet events, `/o/events`, legacy org pet list filter, health dashboard org filter, vet list, org pets secondary filters, manage-fosters approval.

**Keep chips:** notification kind (3), org/manage-fosters tabs, form ChoiceChips, card metadata.
