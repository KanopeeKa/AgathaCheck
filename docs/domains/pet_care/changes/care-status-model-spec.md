---
title: Care status model — care item and care date (simplification)
owner: Product / Agent
audience: both
status: proposed
status_since: 2026-11-03
folds_into: docs/domains/pet_care/features/care-item-evolution.md
last_updated: 2026-11-03
---

# Care status model — care item and care date

**Status:** Proposed — agreed with product owner 2026-11-03. Part of a wider plan still being written; do not
implement from this doc alone.
**Folds into:** [care-item-evolution.md](../features/care-item-evolution.md) (lifecycle, occurrence status) and,
for schedule rules, [care-schedule-management.md](../features/care-schedule-management.md).
**Will supersede (on fold):** D-CIE-002 (no extra stored status), D-CIE-018 (lifecycle), D-CIE-024 (Not recorded as
an open status), D-CIE-034 / CARE-ITEM-R-008 (stack), CARE-ITEM-R-002 / D-CIH-013 (Finished/Archived chip), Restore
and `/reopen`.

## Problem

- A care date has three stored statuses (`pending`, `completed`, `skipped`) and four hidden close reasons (`user`,
  `not_recorded`, `paused`, `system`). History does not receive the reason, so dates the system closed show as
  **Skipped** — the user never skipped them.
- A care item has five lifecycle words (Active, Paused, Finished, Archived, Deleted). Finished and Archived are
  identical on the wire (`status = 'completed'`), so a "closed care" list cannot be built.
- "Not recorded" is both an open status (stack, Review, Record earlier doses) and a close reason.

## Care date — outcome and timing

Two layers. The **outcome** is stored. The **timing** is computed and only applies to Open dates.

| Outcome (stored) | Meaning | Set by |
|---|---|---|
| Open | Still to do | — |
| Done | It happened | User |
| Skipped | Someone decided not to do it | User only |
| Not recorded | The date passed and nobody recorded it — the one thing we know | System only |

| Timing (computed, Open only) | When |
|---|---|
| Upcoming | Future |
| Due | Today, before its time |
| Overdue | Past its time, still open |

There is no "closed" status for a care date, and no "cancelled": dates that had not come due when a schedule
changes, pauses or ends are removed, not kept.

## Care item — three statuses

| Status | Meaning | Subtitle |
|---|---|---|
| Active | Scheduling normally | — |
| Paused | No new dates; can resume | "Paused since 1 Sep" / "Paused until 12 Oct" |
| Closed | Nothing more will happen; read-only and final | **Ended** (one-off done, or recurring care that reached its end) · **Stopped by you** (user closed it) |

Delete remains an action, not a status.

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-STATUS-R-001 | A care date stores exactly one outcome: Open, Done, Skipped or Not recorded; `close_reason` is retired (an audit `closed_by: user \| system` may remain) | Planned |
| CARE-STATUS-R-002 | Timing words Upcoming, Due, Overdue are computed in the pet's home timezone and shown only on Open dates | Planned |
| CARE-STATUS-R-003 | Skipped is written only by a user action; the system never writes Skipped | Planned |
| CARE-STATUS-R-004 | Not recorded is written only by the system; it replaces every system-closed "Skipped" in History and agenda copy | Planned |
| CARE-STATUS-R-005 | Fixed schedule: an Open dose becomes Not recorded when the next dose of the same item is due; it leaves Needs attention and appears in History | Planned |
| CARE-STATUS-R-006 | A Not recorded date can be recorded as Done or Skipped from History while its care item is Active or Paused | Planned |
| CARE-STATUS-R-007 | After it's done schedules have no next dose to trigger R-005: an Overdue date stays Open until the user acts or the item is paused or closed | Planned |
| CARE-STATUS-R-008 | Pausing or closing a care item: Open dates whose time has passed become Not recorded; Open dates not yet due are removed | Planned |
| CARE-STATUS-R-009 | Care item status is one of Active, Paused, Closed | Planned |
| CARE-STATUS-R-010 | A Closed item carries a closed reason shown as subtitle: Ended (one-off done or recurring end reached, no distinction) or Stopped by you | Planned |
| CARE-STATUS-R-011 | Closed is final and read-only: no reopen, no restore, no edit, no date actions; History is frozen | Planned |
| CARE-STATUS-R-012 | No reason is asked when the user skips a date | Planned |
| CARE-STATUS-R-013 | Existing data migrates: `skipped/user` → Skipped; `skipped/not_recorded` → Not recorded; `skipped/system` or `skipped/paused` already due → Not recorded, not yet due → removed; `completed` → Done; items Finished → Closed · Ended; items Archived → Closed · Stopped by you | Planned |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-STATUS-D-001 | Care date = stored outcome (Open, Done, Skipped, Not recorded) + computed timing (Upcoming, Due, Overdue) | Separates "what happened" from "how urgent"; removes hidden close reasons | Planned | 2026-11-03 | — |
| CARE-STATUS-D-002 | Skipped means a human decision only | "Skipped" on system-closed dates misleads users | Planned | 2026-11-03 | — |
| CARE-STATUS-D-003 | System outcome wording is **Not recorded** (FR existing string), not "Unknown" | It states the one fact we know: nothing was recorded | Planned | 2026-11-03 | — |
| CARE-STATUS-D-004 | A Fixed-schedule dose does not "close": it becomes Not recorded when the next dose is due, and can still be recorded | No "closed" status for care dates; removes open stacks and Review | Planned | 2026-11-03 | — |
| CARE-STATUS-D-005 | No "cancelled" outcome: not-yet-due dates are removed when a schedule changes, pauses or closes | Dates that never came due never existed for the pet | Planned | 2026-11-03 | — |
| CARE-STATUS-D-006 | Care item statuses: Active, Paused, Closed | Merges Finished, Archived and "close care" into one final state | Planned | 2026-11-03 | — |
| CARE-STATUS-D-007 | Closed subtitle: **Ended** (natural end, one-off or recurring, no distinction) or **Stopped by you** | One status, reason as context | Planned | 2026-11-03 | — |
| CARE-STATUS-D-008 | No skip reason for now | Keep the first version simple | Planned | 2026-11-03 | — |

## Open questions

| Topic | Options | Notes |
|---|---|---|
| Name of the list of Closed items under All care | "Previous care" · "Closed care" | Product owner undecided (2026-11-03) |
| "Close care" flow on Care details | Button, confirmation, permissions | Next step of the wider plan |
