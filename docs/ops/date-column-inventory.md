---
title: DATE column inventory (TZ-4)
owner: Ops
audience: agent
status: active
last_updated: 2026-10-05
tags: [ops, postgres, calendar-dates]
---

# DATE column inventory (TZ-4)

Wire format for PostgreSQL `DATE` columns is always **`YYYY-MM-DD`** (see `docs/architecture/calendar-dates.md` and `server/lib/db/pgTypes.js`).

## Care / health (high risk during TZ incidents)

| Table | Column | Notes |
|-------|--------|--------|
| `health_entries` | `schedule_anchor_date`, `next_due_date`, `series_resumed_on`, `paused_until`, `paused_since`, `start_date`, `completed_on` | Item-level calendar fields |
| `health_occurrences` | `scheduled_date`, `series_date`, `completed_on` | Occurrence slots |
| `pets` | `birth_date` | Profile |

## Other app tables

Weight entries, planned absences, and audit tables also store calendar dates — search migrations for `DATE` when extending repair tooling.

## Ops

- **Read-only SQL:** `node server/scripts/ops/sql_readonly.js` (loads `server/.env`).
- **D5 manual review:** `node server/scripts/care/repair_tz_shift.js --report-d5 [--since=YYYY-MM-DD]`.

Pool bootstrap guard: `node scripts/check_pg_pool_bootstrap.js` (includes `scripts/care/`).
