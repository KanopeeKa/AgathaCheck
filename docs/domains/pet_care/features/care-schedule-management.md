---
title: Care Schedule Management
owner: Product / Agent
audience: both
domain: pet_care
feature_id: care_schedule_management
status: active
related_prs: []
---

# Care Schedule Management

**Internal name:** CSM  
**Layer:** Authoritative scheduling core of `care_planning`

CSM defines how AgathaTrack **creates, projects, changes, and explains the timing of care** — recurring and non-recurring, single and multiple times per day — while preserving a trustworthy care history.

CSM owns **timing**. It does not own care meaning (`care_core`), suggestion-worthiness (`care_intelligence`), maturity (`care_progression`), or presentation (`care_presentation`).

```text
care_core (CareFamily, capabilities)
        ↑
   CARE SCHEDULE MANAGEMENT
   (depth of care_planning)
   ↑        ↑             ↑
care_context  care_progression  care_intelligence
        ↓
  care_presentation
```

**Dependency rule:** Everything above reads from CSM. CSM depends on nothing above it.

**Delivery status:** Care Schedule Management v1 shipped to `main` via programme integration ([#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193), 2026-09-15). All primitives below are live; the CSM-17 integration gate passed before merge ([#1192](https://github.com/KanopeeKa/AgathaCheck/pull/1192)). See [care-schedule-management-delivery-plan.md](../changes/care-schedule-management-delivery-plan.md) and [decision log](../changes/care-schedule-management-decisions.md).

| Phase | Status | Notes |
|-------|--------|-------|
| CSM-1 | Shipped | `care_schedule_events`, `completion_timing`, `paused_since`, `schedule_policy_version` |
| CSM-2 | Shipped | `server/lib/care/schedule/` + per-family anchor defaults on create |
| CSM-3 | Shipped | Unified `advanceSeries()` |
| CSM-4 | Shipped | No `anchor+1` pre-materialisation (D-CSM-004) |
| CSM-5 | Shipped | `completeOccurrence` (+ weight atomic path via `complete-weight`) |
| CSM-6 | Shipped | `skipOccurrence` + ledger `skipped` events |
| CSM-7 | Shipped | Entry-level `skip`/`unskip` removed; `mark-taken` delegates to oldest pending occurrence; **no new `health_history` writes** |
| CSM-8 | Shipped | `undoLastAction` (timestamp-aware); retires `undo-complete` guessing |
| CSM-9 | Shipped | `pauseSeries` / `resumeSeries` (no catch-up on resume) |
| CSM-10 | Shipped | `rescheduleOccurrence` |
| CSM-11 | Shipped | `adjustCadence` |
| CSM-12 | Shipped | `projectSchedule` refactor from `projectCareForPeriod` |
| CSM-13 | Shipped | `explainGap` read API |
| CSM-14 | Shipped | Care Context thin caller over `projectSchedule` |
| CSM-15 | Shipped | Flutter: client `snooze()` removed |
| CSM-17 | Shipped | Integration gate — projection corpus, CP weight evidence, CIM baseline (`integrationGate.test.js`) |

---

## Primitives

One entry point per real-world action. No primitive writes to more than one authoritative system.

| Primitive | Purpose | HTTP route (when mounted) |
|-----------|---------|---------------------------|
| `completeOccurrence` | Close occurrence; store `completion_timing`; call `advanceSeries()` | `POST …/occurrences/:occId/complete` **(shipped)** |
| `skipOccurrence` | Close as skipped; write `care_schedule_events` | `POST …/occurrences/:occId/skip` **(shipped)** |
| `rescheduleOccurrence` | Move one occurrence; preserve original `scheduled_date` on event | `POST …/occurrences/:occId/reschedule` **(shipped)** |
| `pauseSeries` | Stop generation from date; `status = paused` | `POST …/:id/pause` **(shipped)** |
| `resumeSeries` | Resume with **no catch-up** | `POST …/:id/resume` **(shipped)** |
| `adjustCadence` | Change series rule forward from `effective_from` only | `POST …/:id/adjust-cadence` **(shipped)** |
| `projectSchedule` | Read-only projection with per-item certainty | Consumed by care-period projection **(shipped)** |
| `explainGap` | Read-only schedule facts for CIM | `GET …/:id/schedule-explain` **(shipped)** |
| `undoLastAction` | Timestamp-aware reversal of last schedule action | `POST …/:id/schedule/undo` **(shipped)** |

Internal: **`advanceSeries(entryId)`** — unified rollover after all slots on the earliest open date close (`server/lib/care/schedule/advanceSeries.js`).

Batch helpers: `skipMissedOccurrences` backs `POST …/occurrences/skip-missed` and the `skip_earlier_missed` flag on complete.

---

## HTTP API (health entries)

All routes mount under `/api/health-entries` and `/backend/api/health-entries`. Calendar dates on the wire: `YYYY-MM-DD` ([calendar-dates.md](/docs/architecture/calendar-dates.md)).

### Shipped

| Method | Path | Body | Response |
|--------|------|------|----------|
| GET | `/:id/occurrences` | Query: `status=open` (default) or `status=past`; optional `as_of` | Open or closed occurrence rows |
| POST | `/:id/occurrences/:occId/complete` | `{ completed_on?, notes?, skip_earlier_missed? }` | `{ occurrence, next_due_date }`; sets `completion_timing` |
| POST | `/:id/occurrences/:occId/skip` | `{ notes? }` | Skipped occurrence; ledger `skipped` event |
| POST | `/:id/occurrences/skip-missed` | `{ as_of? }` | `{ skipped[], count }` |
| POST | `/:id/occurrences/:occId/undo` | — | Re-opens occurrence **(superseded by `undoLastAction`)** |
| POST | `/:id/mark-taken` | `{ completed_on?, notes? }` | **Deprecated compat** — completes oldest pending via `completeOccurrence`; returns entry map; **no `health_history` write** |
| POST | `/:id/pause` | `{ paused_from?, reason_note? }` | `status = paused`, `paused_since` cache (from `paused_from` calendar day), ledger `paused` event (D-CSM-005) |
| POST | `/:id/resume` | `{ reason_note? }` | `status = active`; ledger `resumed`; **no catch-up** for paused window |
| POST | `/:id/occurrences/:occId/reschedule` | `{ new_scheduled_date, new_scheduled_time?, reason_note? }` | Moves one pending occurrence; ledger `rescheduled` with `from_date` = original `scheduled_date` (D-CSM-006) |
| POST | `/:id/adjust-cadence` | `{ effective_from, frequency?, frequency_interval?, recurrence_anchor?, reason_note? }` | Series-forward rule change; ledger `cadence_adjusted`; past occurrences immutable |
| POST | `/:id/schedule/undo` | — | Timestamp-aware undo of last schedule action; retires `undo-complete` guessing |
| GET | `/:id/schedule-explain` | Query: optional window | Structured schedule facts for CIM — no explained/unexplained vocabulary |

Weight monitoring: use `POST /api/pets/:petId/care-rhythms/:entryId/occurrences/:occurrenceId/complete-weight` — generic complete and `mark-taken` return `400`.

**Removed (CSM-7):** `POST /:id/skip`, `POST /:id/unskip` — use occurrence skip APIs.

---

## Recurrence anchor defaults (D-CSM-001)

Applied on **create** when `recurrence_anchor` is omitted (`resolveRecurrenceAnchorForWrite` in `recurrenceAnchorDefaults.js`). Explicit guardian choice always overrides.

| Care family | Default `recurrence_anchor` |
|-------------|----------------------------|
| `vaccination` | `from_due_date` |
| `parasite_prevention` | `from_due_date` |
| All other recurring families | `from_completion` |

### `from_completion` meaning (non-clinical families)

Next due date = **N frequency units after actual completion**. Late completions compound drift intentionally. For fixed clinical cadence, use `from_due_date` or explicit `adjustCadence`.

`completion_timing` (`early` | `on_time` | `late`) is stored at write time on complete; **informational in v1** — does not alter `advanceSeries` (D-CSM-002).

### Reschedule vs cadence change (D-CSM-006)

Moving one occurrence is **local** (`rescheduleOccurrence`). Changing the pattern going forward is **explicit** (`adjustCadence`). Never conflate.

---

## `health_history` retirement (D-CSM-003)

`health_history` is **retired for complete/skip purposes**:

- **CSM-7:** No new `health_history` rows on complete or skip; occurrence rows + `care_schedule_events` are authoritative.
- `GET /:id/history` remains read-only for legacy rows until table drop.
- `POST /:id/undo-complete` and per-occurrence `undo` are **legacy** — replaced by `undoLastAction` (CSM-8).
- Table stays in place until a later cleanup migration; no backfill into `care_schedule_events`.

---

## Data model (summary)

**Existing (retained):** `health_entries`, `health_occurrences`

**Additions (CSM-1):**

- `health_entries`: `paused_since`, `schedule_policy_version`; `status` includes `paused`
- `health_occurrences`: `completion_timing` (`early` | `on_time` | `late`), stored at write time
- `care_schedule_events`: append-only ledger — `skipped`, `rescheduled`, `paused`, `resumed`, `cadence_adjusted`; tagged with `policy_version` (`1.0.0`)

---

## Domain interfaces

| Domain | Reads | Writes |
|--------|-------|--------|
| [care_context](./care-context.md) | `projectSchedule` (care-period projection) | — |
| [care_intelligence](./care-intelligence.md) | `explainGap` | — |
| [care_progression](./care-progression.md) | pause/resume events | — |
| `care_presentation` | recent schedule events | — |
| [care_entitlements](./care-entitlements.md) | primitive gates | — |

Care Through Change reschedule/pause **UI** (post–CC-4 tranche) is unblocked — the CSM-17 integration gate cleared on merge to `main` (D-CSM-008).

---

## Related

- [occurrence-scheduling.md](/docs/domains/health_tracking/changes/occurrence-scheduling.md) — occurrence materialisation and UI zones (behaviour owned by CSM)
- [api-reference.md](/docs/architecture/api-reference.md) — endpoint index
- [calendar-dates.md](/docs/architecture/calendar-dates.md) — `YYYY-MM-DD` wire format for schedule fields
