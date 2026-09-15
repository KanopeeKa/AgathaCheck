---
title: Care Schedule Management
owner: Product / Agent
audience: both
domain: pet_care
feature_id: care_schedule_management
status: draft
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

**Delivery status:** Runtime implementation in progress (CSM-1 schema landed; CSM-2 per-family anchor defaults on create). See [care-schedule-management-delivery-plan.md](../changes/care-schedule-management-delivery-plan.md) and [decision log](../changes/care-schedule-management-decisions.md).

---

## Primitives (target API)

One entry point per real-world action. No primitive writes to more than one authoritative system.

| Primitive | Purpose |
|-----------|---------|
| `completeOccurrence` | Close occurrence; store `completion_timing`; call `advanceSeries()` |
| `skipOccurrence` | Close as skipped; write `care_schedule_events` |
| `rescheduleOccurrence` | Move one occurrence; preserve original `scheduled_date` on event |
| `pauseSeries` | Stop generation from date; `status = paused` |
| `resumeSeries` | Resume with **no catch-up** |
| `adjustCadence` | Change series rule forward from `effective_from` only |
| `projectSchedule` | Read-only projection with per-item certainty |
| `explainGap` | Read-only schedule facts for CIM (no explained/unexplained vocabulary) |
| `undoLastAction` | Timestamp-aware reversal of last schedule action |

Internal: **`advanceSeries(entryId)`** — unified rollover after all slots on the earliest open date close.

---

## Recurrence anchor defaults

| Care family | Default anchor |
|-------------|----------------|
| `vaccination` | `from_due_date` |
| `parasite_prevention` | `from_due_date` |
| All other recurring families | `from_completion` |

Explicit guardian choice always overrides. See [D-CSM-001](../changes/care-schedule-management-decisions.md).

### `from_completion` meaning (non-clinical families)

Next due date = **N frequency units after actual completion**. Late completions compound drift intentionally. For fixed clinical cadence, use `from_due_date` or explicit `adjustCadence`.

### Reschedule vs cadence change

Moving one occurrence is **local** (`rescheduleOccurrence`). Changing the pattern going forward is **explicit** (`adjustCadence`). Never conflate.

---

## Data model (summary)

**Existing (retained):** `health_entries`, `health_occurrences`

**Additions:**

- `health_entries`: `paused_since`, `schedule_policy_version`; `status` includes `paused`
- `health_occurrences`: `completion_timing` (`early` \| `on_time` \| `late`), stored at write time
- `care_schedule_events`: ledger for skip, reschedule, pause, resume, cadence_adjusted

`health_history` is retired for complete/skip purposes — no new writes after CSM-7.

---

## Domain interfaces

| Domain | Reads | Writes |
|--------|-------|--------|
| `care_context` | `projectSchedule` | — |
| `care_intelligence` | `explainGap` | — |
| `care_progression` | pause/resume events | — |
| `care_presentation` | recent schedule events | — |
| `care_entitlements` | primitive gates | — |

---

## Related

- [care-context.md](./care-context.md) — care-period projection consumer
- [care-progression.md](./care-progression.md) — weight occurrence evidence
- [care-intelligence.md](./care-intelligence.md) — gap explanation consumer
- [occurrence-scheduling.md](/docs/domains/health_tracking/changes/occurrence-scheduling.md) — current occurrence materialisation (superseded by CSM for behaviour)
