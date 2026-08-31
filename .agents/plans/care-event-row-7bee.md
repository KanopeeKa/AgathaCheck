# Care event row unification

> **plan_id:** `care-event-row-7bee`  
> **Approved:** user chat 2026-08-31 (`/execute-plan` + `/ui-design-deep`)

## Goal

Unify dashboard Care preview, pet Due/overdue preview, and `/g/events` on one scannable `CareEventRow`. Row tap opens the existing event view screen; snooze and edit move off list rows onto view. Mark done stays on the row with the existing completion sheet.

## Locked decisions

| Topic | Decision |
|-------|----------|
| List row actions | Done only on row; no snooze, open, or edit on list |
| Row tap | `/pet/:petId/events/:entryId` (view), not edit |
| Snooze | View screen only (`PetEventViewScreen`) |
| Edit | App bar on view only (body Edit button removed) |
| Desktop | Same `CareEventRow` at all widths |
| Optimistic complete | Dashboard + global list only; pet preview uses server refresh |
| Primary action label | Always "Mark as done" |

## Phase 1 — CareEventRow + view hub

**Branch:** `cursor/care-event-row-unification-7bee`

**Deliverables:**

- `CareEventRow`, `CareEventRowPetAvatar`, `care_event_status_line.dart`
- Wire dashboard, pet preview, `/g/events`
- Refactor `PetEventViewBody` occurrence actions (mark done + snooze)
- Remove `DueEventCard`, `MobileDueEventRow`, `DesktopCareRow`
- Update unit, BDD, Playwright tests
- Supersede W07/W08 briefs

**Exit criteria:**

- [x] Same row component on dashboard + pet preview + global list
- [x] Row opens view; snooze on view only
- [x] Mark-complete sheet preserved
- [x] Tests updated
