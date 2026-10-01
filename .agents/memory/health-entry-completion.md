---
name: Care item completion / occurrence semantics
description: Occurrences are the source of truth — always one real open date, two schedule types, commands under one lock (2026-09-29)
---

**Source of truth:** `health_occurrences` rows + the `care_schedule_events` ledger. `health_history` is retired (D-CSM-003); the `9999` sentinel is legacy read-only.

**Guarantee (D-CSM-019):** every active planned care item always has ≥ 1 stored open occurrence (`status = 'pending'`), created in the **same transaction** as the command that needs it. No T−1 window, no "ensure" step. `health_entries.next_due_date` is a derived cache = earliest open occurrence; only `syncOpenOccurrences` writes it. `PUT` does not (D-CSM-032).

**Schedule types (D-CSM-020, wire unchanged):**
- `from_due_date` = **Fixed schedule** (default for `medication`) — dates from `schedule_anchor_date`; slots from today − 3 through today + the next series date are stored; missed slots become **Not recorded** (stack), closed as `not_recorded` after 3 days, recordable later.
- `from_completion` = **After it's done** (default for every other family) — one open date; next = done date + interval; overdue until done/skipped/postponed.

**Origins (D-CSM-021):** `schedule` · `computed` (≤ 1 open, only when nothing else is open) · `planned` (set by a person; never moved by the app).

**Complete:** `POST …/occurrences/:occId/complete { completed_on?, next_choice?, remember_choice? }`. Never asks (D-CSM-026 revised 2026-10-01): with no `next_choice` the remembered choice applies if it fits, otherwise `keep`; the response says which in `next_choice_applied`. An explicit choice that doesn't fit → 400 `next_choice_not_available`. Same on `complete-weight`. No `earlier_choice` → the earlier After-it's-done date stays open. **409 `occurrence_not_open`** when already closed. Overdue items ask "When was this done?" first (D-CIE-009).

**Undo (D-CSM-029):** reverses the whole last command; deletes a created next date only if still `computed`.

**Every command** runs in `withCareItemLock` (transaction + row lock), catches up Fixed-schedule slots first, ends with `syncOpenOccurrences`; side effects after commit. Only `server/lib/care/occurrence/**` may write `health_occurrences` (`scripts/check_occurrence_writes.js`).

**"Today"** = pet home timezone, supplied by the server as `as_of`. Test clock header `X-Care-As-Of` works only in development/test/ci.

Canonical docs: `docs/domains/pet_care/changes/care-schedule-management-decisions.md` (D-CSM-019…033), `docs/domains/health_tracking/changes/occurrence-scheduling.md` (case matrix), `docs/domains/pet_care/features/care-item-evolution.md` (D-CIE-024…028).
