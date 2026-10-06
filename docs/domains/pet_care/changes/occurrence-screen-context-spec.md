---
title: Spec — Care date screen (occurrence leaf)
owner: Product / Design
audience: both
status: agreed
last_updated: 2026-10-06
tags: [pet_care, care_item, ux, accessibility, l10n]
---

# Spec — Care date screen (occurrence leaf)

**Status:** **agreed** (2026-10-06)  
**Surface:** Flutter Care date route (`OccurrenceScreen`, occurrence widgets, l10n, widget/E2E tests). No server change in v1.

**Related**

| Document | Relationship |
|----------|----------------|
| [care-item-context-header-spec.md](./care-item-context-header-spec.md) | Parent Care details context strip (paired leaf screen) |
| [care-item-evolution.md](../features/care-item-evolution.md) | D-CIE-029 occurrence screen; absences § |
| [terminology.md](../../../design/terminology.md) | Status labels; no “occurrence” in UI |

**Out of scope (separate programmes)**

- Pre-departure / “due before you leave” UX
- Post-skip optional reason field
- Generic **re-open any past date** (`reopen` API — D-OCC-013)
- App bar ⋯ menu; **Pause until**, **Plan another date**, stub **Add note** (Care details only)
- **Postpone until** on this screen (series pause — Care details only)

## Decision log

| ID | Decision |
|----|----------|
| D-OCC-001 | App bar: **Care date** |
| D-OCC-002 | Context tile → Care details; card/ink; **no chevron** |
| D-OCC-003 | Pet medallion + name (non-link); care name; lifecycle chip; open count rules §5.2 |
| D-OCC-004 | Title row: **scheduled date/time only** (care name on tile) |
| D-OCC-005 | Sections: Status → Away (conditional) → Actions |
| D-OCC-006 | **Reschedule** = this occurrence only (`changeDate`); EN **Reschedule**, FR **Replannifier** |
| D-OCC-007 | No Reschedule on closed–not-recorded, Done, Skipped |
| D-OCC-008 | Open Actions: completion date + **Mark as done** (filled) + **Skip** (outlined) |
| D-OCC-009 | Open **not recorded**: **Mark as done** + Skip; **Record as done** only on closed–not-recorded |
| D-OCC-010 | Done: completion date **editable** (D-CSM-034); other fields read-only |
| D-OCC-011 | **Undo v1:** label from `lastAction.type` — **`careUndoDateChange`** or **`snackbarUndo`**; not “Re-open” |
| D-OCC-012 | Show Undo when **`canUndoHere`**, including when series is **finished** (restores `entry_before`) |
| D-OCC-013 | When series finished and **`!canUndoHere`**: static copy only (no disabled button) |
| D-OCC-014 | Away: open occurrence + date in `[startsOn, endsOn]`; **keep_date** is **absence-wide** — explainer required |
| D-OCC-015 | Resolved keep: **In {name}'s cover plan** / **In cover plan** |
| D-OCC-016 | No ⋯ menu |
| D-OCC-017 | Closed–not-recorded: Record as done + Confirm not done; no Reschedule |
| D-OCC-OUT-1 | Plan another date / Pause until: Care details only |

## UX — state table

| State | Reschedule | Actions |
|-------|------------|---------|
| Open (due/overdue/upcoming) | Yes | Completion date; Mark as done; Skip |
| Open not recorded | Yes | Mark as done; Skip |
| Closed not recorded | No | Record as done; Confirm not done |
| Done | No | Editable completion date; Undo if `canUndoHere` |
| Skipped | No | Read-only; Undo if `canUndoHere` |

**Reschedule (open not recorded):** picker `firstDate` is today (forward-only moves); past slots are closed via Mark as done / Skip.

**Pet tile:** loads `petByIdProvider`; skeleton until pet resolves.

## Analytics

| Kind | Names |
|------|--------|
| **Events** | `occurrence_screen_opened`, `care_completion_date_changed`, `care_stack_resolved` |
| **Widget keys (tests)** | `occurrence_reschedule`, `occurrence_done`, `occurrence_skip`, `occurrence_undo`, `occurrence_confirm_skip`, `occurrence_context_tile` |

Optional future: `occurrence_rescheduled` analytics event (not required v1).

## Acceptance criteria

See plan `occurrence-screen-context-6b05` phase exit checklist (AC-1 … AC-30).
