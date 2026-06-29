---
name: Health entry completion / overdue semantics
description: Three-date model — due, completed on, marked at — and recurrence anchor modes
---

The Flutter `HealthEntry` entity tracks:
- `nextDueDate` (a) — when the current/upcoming occurrence is due; null when completion-only one-time entries
- `completedOn` (b) — when a one-time entry was completed
- History rows store `due_date`, `completed_on`, `marked_at` (c), and `marked_by_user_id`

**Completion state (one-time):** `completedOn != null` (legacy `nextDueDate.year >= 9999` still read for backward compat).

**Recurring:** series stays open; each `mark-taken` writes a history row and advances `nextDueDate`.

**Recurrence anchor** (`recurrence_anchor` on `health_entries`):
- `from_completion` (default for **new** entries) — next due = completed on + interval
- `from_due_date` (backfilled on **existing** recurring entries at migration) — next due = original due + interval

**Rule:** `mark-taken` accepts optional `completed_on` in the body (defaults to today). `marked_at` and user are set server-side.

**Undo:** reverts the latest history row and restores `next_due_date` / clears `completed_on` on the entry.

Keep Node (`server/routes/healthEntries.js`) and Dart (`server/lib/health_routes.dart`) handlers in lockstep via `server/lib/recurrenceHelper.js`.

**Org family events:** `from_date` = due, `to_date` = completed on; `family_event_history` stores the three-date audit trail.
