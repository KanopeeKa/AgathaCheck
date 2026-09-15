---
title: Health occurrence scheduling
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-15
tags: [domain, health_tracking, occurrences]
domain: health_tracking
---

# Health occurrence scheduling

Canonical spec for timestamp-aware care occurrences. Implements multi-dose-per-day tracking as first-class `health_occurrences` rows.

> **CSM ownership:** Write behaviour (complete, skip, rollover, pause, reschedule, cadence) is owned by [Care Schedule Management](/docs/domains/pet_care/features/care-schedule-management.md). This document covers **materialisation**, **missed predicates**, and **UI zones**. Use occurrence HTTP APIs — not legacy entry-level complete/skip paths.

## Goals

- Every scheduled instant is an occurrence: `(scheduled_date, scheduled_time)` where `scheduled_time` may be `NULL` (all-day).
- One `HealthEntry` series drives many occurrences; lists show one row per series; event view shows every open occurrence.
- Missed backlog uses humane stack UX with opt-in skip of earlier missed doses.

## Data model

### `health_occurrences`

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK |
| `health_entry_id` | UUID | FK → `health_entries` |
| `scheduled_date` | DATE | Calendar day (`YYYY-MM-DD` wire) |
| `scheduled_time` | TIME | Local wall-clock; `NULL` = all-day |
| `status` | VARCHAR | `pending` \| `completed` \| `skipped` |
| `completed_on` | DATE | When given (calendar day) |
| `completion_timing` | VARCHAR | `early` \| `on_time` \| `late` — set on complete (CSM-5) |
| `marked_at` | TIMESTAMPTZ | Audit instant |
| `marked_by_user_id` | UUID | FK → `users` |
| `notes` | TEXT | Optional |

Unique pending constraint per entry + instant: `(health_entry_id, scheduled_date, scheduled_time)` where status is open.

### Series template on `health_entries`

| Column | Type | Notes |
|--------|------|-------|
| `schedule_times` | JSONB | Ordered `["08:00","18:00"]`; empty/null with checkbox off → all-day (`NULL` time) |
| `recurrence_anchor` | VARCHAR | `from_completion` \| `from_due_date` — default from care family on create (D-CSM-001) |
| `paused_since` | DATE | Set when series paused (CSM-9) |
| `schedule_policy_version` | VARCHAR | CSM policy tag on entry |

## Timezone & overdue

Follow `docs/architecture/calendar-dates.md`:

- Schedule uses `DATE` + `TIME` (local wall clock), not `TIMESTAMPTZ` for dose instants.
- `marked_at` uses `TIMESTAMPTZ`.
- **Today** and **missed** predicates use **device local** calendar (same helpers as `calendar_date.dart`).

### `is_missed(occ, nowLocal)`

**Timed** (`scheduled_time` set):

```
pending AND (
  scheduled_date < today_local
  OR (scheduled_date = today_local AND now_local > scheduled_instant)
)
```

**All-day** (`scheduled_time` null):

```
pending AND scheduled_date < today_local
```

## Materialisation (lazy roll-forward)

Anchor: `materialisation_anchor = max(start_date, today_local)` — no backfill of past pending rows.

| Series type | At creation | Next batch |
|-------------|-------------|------------|
| **Once** | Single occurrence | — |
| **Repeating ≤1×/day** | First occurrence on anchor day | Next series date when previous **closes** (done/skipped) via `advanceSeries`, **OR** calendar **T−1** for target day — whichever is first |
| **Repeating >1×/day** | All slots on anchor day only (no `anchor+1` pre-batch) | Next series date batch when **all anchor-day occurrences close** via `advanceSeries`, **OR** calendar **T−1** for target day — whichever is first |

**T−1** means `today_local >= scheduled_date - 1 calendar day`.

**Create-time rule (D-CSM-004):** multi-per-day entries materialise **only** the anchor day at create. The next calendar day is never pre-materialised early; rollover is unified in `advanceSeries()` (`server/lib/care/schedule/advanceSeries.js`).

**Once** series may keep explicit past `scheduled_date` when user sets a historical appointment.

## Zones & sort (UI)

| Zone | Condition | Sort |
|------|-----------|------|
| **Missed** | `is_missed` | LIFO `(date, time) DESC` |
| **Due today** | today, not missed | FIFO ASC |
| **Coming up** | `scheduled_date > today` | FIFO ASC |

**List row headline:** missed LIFO head if any missed; else FIFO head of due today / coming up.

**Mark latest** on stack sheet = head of **Missed** zone only (not a future coming-up row).

## Surfaces

### Dashboard lists (`CareEventRow`)

- One row per series; occurrence-aware status line; **Done** opens stack sheet when `open_count > 1` OR `missed_count >= 1`.
- Row tap → event view.

### Stack sheet (triage)

- Zones as above (hide empty zones).
- Opt-in checkbox: skip earlier missed when recording missed head (only if `missed_count > 1`).
- Actions: Record head, Review each dose → event view, Skip all missed, Not now.

### Event view (workbench)

- Open occurrences (full zoned list), per-row Mark done / Skip, footer Skip all missed.
- Past occurrences collapsed (completed + skipped, LIFO).
- Series edit / close; **no snooze** (client `snooze()` removed in CSM-15).

## API

**Canonical reference:** [care-schedule-management.md](/docs/domains/pet_care/features/care-schedule-management.md) and [api-reference.md](/docs/architecture/api-reference.md).

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/health-entries/:id/occurrences` | List open (`status=open`) or past (`status=past`) |
| POST | `/api/health-entries/:id/occurrences/:occId/complete` | Complete one occurrence via `completeOccurrence` |
| POST | `/api/health-entries/:id/occurrences/:occId/skip` | Skip one via `skipOccurrence` |
| POST | `/api/health-entries/:id/occurrences/skip-missed` | Bulk skip missed |
| POST | `/api/health-entries/:id/occurrences/:occId/undo` | Legacy per-occurrence undo (superseded by CSM-8) |

### Deprecated / removed paths

| Path | Status |
|------|--------|
| `POST /:id/mark-taken` | **Deprecated** — completes oldest pending occurrence only; no `health_history` write. Prefer `…/occurrences/:occId/complete`. |
| `POST /:id/skip`, `POST /:id/unskip` | **Removed** (CSM-7) — use occurrence skip APIs. |
| `POST /:id/undo-complete` | **Legacy** — replaced by `undoLastAction` (CSM-8). |
| `GET /:id/history` | **Read-only** legacy `health_history` rows (D-CSM-003); not written on new completes/skips. |

### E2E seeding (Playwright `api.ts`)

Create a twice-daily series and list open occurrences:

```json
POST /api/health-entries
{
  "pet_id": "<petId>",
  "name": "Twice Daily Meds",
  "type": "medication",
  "frequency": "daily",
  "next_due_date": "2026-09-02",
  "schedule_times": ["08:00", "18:00"]
}
```

```http
GET /api/health-entries/<entryId>/occurrences
```

Returns two pending rows for the anchor day when `schedule_times` has two slots.

> **Note:** Node `pg` requires `JSON.stringify` for JSONB bind parameters; until the create route normalises `schedule_times`, Playwright seeds multi-dose rows via `seedMultiDoseHealthEntry()` in `e2e/playwright/support/api.ts` (SQL patch after a plain create).

Complete one dose:

```json
POST /api/health-entries/<entryId>/occurrences/<occId>/complete
{ "completed_on": "2026-09-02" }
```

## Removed

- Entry-level **snooze** (UI and new occurrence flows).
- Entry-level **skip** / **unskip** (CSM-7).
- **`health_history` writes** on complete/skip (D-CSM-003).
