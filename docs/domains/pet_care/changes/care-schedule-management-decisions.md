---
title: Care Schedule Management — Decision log
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-15
tags: [pet_care, care_planning, decisions]
---

# Care Schedule Management — Decision log

Frozen product and engineering decisions for **Care Schedule Management (CSM)**. Canonical behaviour lives in [care-schedule-management.md](../features/care-schedule-management.md). Delivery sequencing: [care-schedule-management-delivery-plan.md](./care-schedule-management-delivery-plan.md).

**Context:** AgathaTrack is **not in production**; no real user data exists. Decisions below assume a clean cutover — no backfill analysis, no GDPR-export preservation for legacy tables.

---

## D-CSM-001 — Recurrence anchor defaults by care family (2026-09-15)

**Status:** Frozen

| Care family | Default `recurrence_anchor` | Rationale |
|-------------|----------------------------|-----------|
| `vaccination` | `from_due_date` | Clinical interval integrity — aligns with Care Through Change “movable: ask, earlier only, never later” for immunisation schedules |
| `parasite_prevention` | `from_due_date` | Same clinical-interval rationale as vaccination |
| All other recurring families | `from_completion` | Guardian-paced rhythms (medication, grooming, weight monitoring, etc.) |

**Implementation:** Server applies default on create when `recurrence_anchor` is omitted; explicit guardian choice always wins. No migration of existing rows required (no production data).

**Supersedes:** Blanket “freeze `from_completion` for all entries” from the initial CSM verification review.

---

## D-CSM-002 — `from_completion` semantics for non-clinical families (2026-09-15)

**Status:** Frozen

For entries defaulting to `from_completion`:

> The next occurrence date is **N frequency units after the actual completion date** (current `nextOccurrence()` behaviour). Late completions compound drift; that is intentional for guardian-paced care.

Fixed cadence without drift: use `from_due_date` (explicit at create, or the default for vaccination / parasite prevention per D-CSM-001).

`completion_timing` (`early` \| `on_time` \| `late`) is **informational in v1** — stored at write time, not used to alter `advanceSeries` unless a future decision revisits this.

---

## D-CSM-003 — `health_history` retirement (2026-09-15)

**Status:** Frozen

`health_history` is **dead weight**, not an archive:

- Stop all new writes for complete/skip once unified primitives ship (CSM-7).
- Do **not** backfill into `care_schedule_events`.
- Leave the table in place until a later cleanup migration drops it.
- No GDPR-export preservation reasoning — no real user data exists.

---

## D-CSM-004 — Remove multi-day `anchor + 1` pre-materialization (2026-09-15)

**Status:** Frozen

Remove `materialiseInitialOccurrences`’s extra calendar-day batch for multi-per-day entries (`occurrenceScheduling.js` multi-day branch at create).

**Rationale:** Original intent (PR #821) was UX — surface “coming up” tomorrow doses before T−1 fires; not a timezone safeguard. T−1 materialisation (`isWithinMaterialisationWindow`) is sufficient.

**Outcome:** Eliminates structural multi-open-date state; unified `advanceSeries()` handles rollover for single- and multi-per-day paths (CSM-3/4).

---

## D-CSM-005 — Pause resume has no catch-up (2026-09-15)

**Status:** Frozen

`resumeSeries` does **not** backfill occurrences for the paused window. Matches Care Progression rule: pausing does not erase Established status.

---

## D-CSM-006 — Reschedule vs cadence change (2026-09-15)

**Status:** Frozen

| Operation | Scope |
|-----------|-------|
| `rescheduleOccurrence` | One instance; original `scheduled_date` preserved on `care_schedule_events`; does not change series recurrence rule |
| `adjustCadence` | Series going forward only; never rewrites past occurrences |

Manually moving one occurrence does **not** implicitly change anchor or frequency. “Make this fixed going forward” is an explicit `adjustCadence` action.

---

## D-CSM-007 — Demo seed data refresh (2026-09-15)

**Status:** Frozen

Rewrite UAT/demo seed data to exercise CSM edge cases found in code review (minimum coverage list in delivery plan §CSM-SEED). Runs as **CSM-SEED** — parallel dev/test infrastructure after CSM-0; does not block CSM-1 schema work.

---

## D-CSM-008 — Hard gate before Care Through Change reschedule/pause UI (2026-09-15)

**Status:** Frozen

**Satisfied 2026-09-15.** CSM-17 integration gate merged ([#1192](https://github.com/KanopeeKa/AgathaCheck/pull/1192)) and landed on `main` via programme integration ([#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193)). Unified write primitives, `projectSchedule`, `explainGap`, `advanceSeries`, and `care_schedule_events` ledger are live. Care Through Change reschedule/pause UI (post–CC-4 tranche) may proceed.

---

## D-CSM-018 — Intent-based materialisation of the open occurrence (2026-09-28)

**Status:** Frozen (execute-plan `care-absence-materialisation-7796`)

**Problem:** Lazy T−1 materialisation leaves **projected / estimated** in-window dates without a `health_occurrences` row. Skip, reschedule, and absence **Review date** require a materialised **open head** — UI otherwise dead-ends on “Not set” and null `occurrence_id`.

**Decision:** Add **`ensureOpenOccurrence`** — an explicit CSM write that idempotently creates pending row(s) for the **canonical open calendar day** (earliest pending if any; otherwise the next series date computed like `advanceSeries`, without bypassing series bounds).

| Allowed | Not allowed |
|---------|-------------|
| User intent: Review date, Change date, Skip (after ensure), proactive ensure for **affected** absence context on the **open head** | Pre-generating full in-window chains (daily batch) |
| Materialise **one calendar day** (all slots that day for multi-dose) | Materialising a non-head projected hop while an earlier pending day exists (BR-1) |
| Ledger optional `materialised` event for audit | GET-on-read hidden writes |

**Relationship to D-CSM-004:** D-CSM-004 forbids automatic **`anchor+1` at create**. D-CSM-018 is **on-demand** materialisation when the guardian or absence flow needs to act — not series pre-generation.

**Relationship to D-ACP-010:** Schedule-intent records for “fix hop #3 while hop #2 is open” remain **deferred**. D-CSM-018 does **not** reopen D-ACP-010; non-head estimated dates still require handling the **open head** first.

**HTTP:** `POST /api/health-entries/:id/occurrences/ensure-open` (see [api-reference.md](/docs/architecture/api-reference.md)).

**Implementation plan:** `care-absence-materialisation-7796` phases `ensure-server`, `ensure-flutter`, `absence-ux`.
