---
name: Health entry completion / overdue semantics
description: How the Flutter UI decides "overdue" vs "completed" and what mark-taken/undo must do server-side
---

The Flutter `HealthEntry` entity has NO `status`/`completedAt` field — the UI derives
state **entirely from `nextDueDate`**:
- `isCompleted` = `frequency == once && nextDueDate.year >= 9999` (a 9999 sentinel date).
- `isOverdue` = `!isCompleted && nextDueDate` before today.
- Recurring entries have **no "completed" state** in the UI at all; the card only shows
  Done/Undo for `once` entries (driven by `isCompleted`).

**Rule:** anything that "completes" a health entry must change `next_due_date`, not just
the DB `status` column — the UI ignores `status`.
- `mark-taken`: for `once` → set `next_due_date` to the 9999 sentinel; for recurring →
  advance `next_due_date` to the next occurrence (advance by frequency*interval, looping
  until strictly after today so multi-period-overdue entries still land in the future).
- `undo-complete`: must also restore `next_due_date` for `once` entries (back to
  `start_date`) or the UI stays "completed" forever.

**Why:** the original bug — marking an OVERDUE recurring entry complete left it overdue —
was because both backends only did `SET status='completed', completed_at=NOW()` and never
touched `next_due_date`.

**How to apply:** keep the Node (`server/routes/healthEntries.js`) and Dart
(`server/lib/health_routes.dart`) `mark-taken`/`undo-complete` handlers in lockstep —
both run a fetch-then-update with the same recurrence helper. Guard the advance loop
against `frequency_interval`/`frequency_days` ≤ 0 (coerce to ≥1) or it spins forever.
