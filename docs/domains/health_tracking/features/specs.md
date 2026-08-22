---
title: Health tracking specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,health_tracking,specs]
---

# Health tracking specs

## Completion semantics (three-date model)

Core domain semantics — full lesson: [.agents/memory/health-entry-completion.md](/.agents/memory/health-entry-completion.md).

| Field | Meaning |
|-------|---------|
| `nextDueDate` | When the current/upcoming occurrence is due |
| `completedOn` | When a one-time entry was completed |
| History `marked_at` / `marked_by_user_id` | Audit trail on mark-taken |

**One-time completion:** `completedOn != null` (legacy `nextDueDate.year >= 9999` still read for backward compat).

**Recurring:** series stays open; each mark-taken writes history and advances `nextDueDate`.

**Recurrence anchor** (`recurrence_anchor` on `health_entries`):

- `from_completion` — default for new entries; next due = completed on + interval
- `from_due_date` — backfilled on existing recurring entries; next due = original due + interval

**Mark-taken:** optional `completed_on` in body (defaults to today); `marked_at` and user set server-side.

**Undo:** reverts latest history row and restores entry state.

Handler: `server/routes/healthEntries.js`; recurrence helpers: `server/lib/recurrenceHelper.js`.

## Health issues

Managed via `server/routes/healthIssues.js` with separate CRUD from entries.

## Org family events alignment

Org family events use `from_date` = due, `to_date` = completed on; `family_event_history` stores the three-date audit trail (see fostering/organization domains).

---

**Lessons:** [changes/lessons.md](../changes/lessons.md)
