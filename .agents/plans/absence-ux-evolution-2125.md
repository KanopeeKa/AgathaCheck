# Absence UX evolution (title, CRUD create, trip details)

| Field | Value |
|-------|-------|
| **plan_id** | `absence-ux-evolution-2125` |
| **base_branch** | `cursor/absence-ux-evolution-integration-2125` |
| **default_merge_mode** | `auto` |

## Goal

Add optional **title** to planned absences; replace wizard create with a **CRUD-style form** (like pet/vet forms) with inline care preview; show a compact **summary card** on the plan page with local **Edit** (title, dates, notes only — no pet edits in V1); retire app-bar edit and notes-only edit route. Conservative **calendar-date** handling with non-regression tests. Document **D-CC-ABS-001** in `care-context.md`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-07T10:00:00Z |
| **approved_until** | 2026-10-09T10:00:00Z |
| **approved_by** | user chat 2026-10-07 (full approval, /execute-plan) |
| **control_issue** | #1750 |
| **autonomy** | `active` |

## Phases

### Phase 1 — Title API + date non-reg + spec

**branch:** `cursor/absence-ux-title-api-2125`

- Migration `084_planned_absence_title`
- Wire `title` on create/PATCH/GET; normalize (trim, max 60, empty → null)
- Server tests: title + PATCH date round-trip (calendar strings unchanged on wire)
- `care-context.md` Planned requirements + D-CC-ABS-001

### Phase 2 — Plan summary card + trip details form

**branch:** `cursor/absence-ux-plan-ui-2125`

- Summary card; remove duplicate details/notes sections and app-bar edit
- Full-screen trip details form (title, dates, notes, delete); guest widen + date-change confirm
- Title display on hub, tile, home, care-item, PDF, invite; rename user-facing “Trip notes” → **Notes**
- Flutter widget tests; update/remove edit screen tests

### Phase 3 — CRUD create (no wizard)

**branch:** `cursor/absence-ux-create-crud-2125`

- Replace `PlannedAbsenceFlowScreen` wizard with single scroll form + inline preview section
- Update `away-planning.page.ts`, BDD, `away.planning.spec.ts`
- `away-planning-carer-model.md` UI table

## Final integration PR

Integration branch → `main` via `/babysit-uat`.
