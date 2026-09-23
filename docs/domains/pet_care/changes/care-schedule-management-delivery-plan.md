---
title: Care Schedule Management — Delivery Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-23
tags: [pet_care, care_planning, delivery]
---

# Care Schedule Management — Delivery Plan

**Canonical product behaviour:** [care-schedule-management.md](../features/care-schedule-management.md)  
**Frozen decisions:** [care-schedule-management-decisions.md](./care-schedule-management-decisions.md)  
**Execute-plan:** `.agents/plans/care-schedule-management-v1.md`

## Programme goal

Unify care timing under **Care Schedule Management (CSM)** — the authoritative scheduling core of `care_planning`. One primitive per real-world action, one ledger (`care_schedule_events`), one rollover path (`advanceSeries`), no parallel completion/skip systems.

**Pre-production note:** No real user data. Clean cutover; no `health_history` backfill; per-family anchor defaults apply on new writes only.

---

## Shipping gates

All satisfied on merge to `main` (programme integration [#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193), 2026-09-15):

1. **CSM-17** integration gate green — regression suite in `server/test/careSchedule/integrationGate.test.js` ([#1192](https://github.com/KanopeeKa/AgathaCheck/pull/1192)).
2. Care Context `care-period-projection` corpus byte-identical before/after `projectSchedule` refactor (CSM-14).
3. Weight establishment sees only occurrence-linked completions with real weight rows (CSM-5).

Care Through Change reschedule/pause UI (future CC tranche beyond CC-4) is unblocked per D-CSM-008.

---

## Implementation sequence

```text
CSM-0   Decision log + delivery docs + execute-plan bootstrap
CSM-SEED  Rich demo seed data (parallel after CSM-0 — does not block CSM-1)
CSM-1   Schema: care_schedule_events, completion_timing, paused_since, schedule_policy_version
CSM-2   server/lib/care/schedule/ shell + per-family anchor defaults
CSM-3   Unified advanceSeries()
CSM-4   Remove multi-day anchor+1 pre-materialization
CSM-5   completeOccurrence primitive (+ weight atomic path)
CSM-6   skipOccurrence primitive (+ ledger events)
CSM-7   Retire mark-taken fallback, /skip, /unskip; stop health_history writes
CSM-8   undoLastAction (timestamp-aware)
CSM-9   pauseSeries / resumeSeries
CSM-10  rescheduleOccurrence
CSM-11  adjustCadence
CSM-12  projectSchedule (refactor from projectCareForPeriod)
CSM-13  explainGap read API
CSM-14  Care Context thin caller
CSM-15  Flutter: remove client snooze(); wire primitives
CSM-17  Integration gate (CIM, CP weight, CC projection parity)
CSM-18  Canonical docs + cross-doc updates
```

Integration branch: `cursor/care-schedule-management-v1-integration-csm1`

---

## CSM-0 — Decision log + plan bootstrap

- [care-schedule-management-decisions.md](./care-schedule-management-decisions.md)
- This delivery plan
- [care-schedule-management.md](../features/care-schedule-management.md) skeleton
- `.agents/plans/care-schedule-management-v1.*`

**Exit:** Decisions D-CSM-001–008 recorded; execute-plan snapshot validated.

---

## CSM-SEED — Rich demo seed data (parallel)

**Seam:** Own fast-moving PR, starts after CSM-0 merges; runs **in parallel** with CSM-1 onward. Dev/test infrastructure — not scheduling logic — so it does not block schema or primitive work.

**Not folded into CSM-3 test fixtures:** unit tests need deterministic minimal fixtures; seeds need life-like cross-entry narratives for manual QA, UAT, and E2E.

### Minimum scenario coverage (from verification review)

| Scenario | Seed must include |
|----------|-------------------|
| Multi-per-day + non-daily frequency | e.g. twice-daily weekly medication course |
| Vaccination + parasite prevention | `from_due_date` default anchors (D-CSM-001) |
| Other families | `from_completion` default (medication, weight monitoring, grooming) |
| Weight monitoring | Completions via `complete-weight` (occurrence + `weight_entries` linked) |
| Weight blind-spot paths | Entry with no pending occurrences at mark time (far-future `next_due_date`) — **pre-CSM-7 only**, for regression visibility |
| Multi-dose day | Open occurrences across times; partial-day completion state |
| `from_completion` chain | Entry with pending occurrence + projection uncertainty window |
| Post-CSM-9/10 (extend seed in follow-up PRs) | Paused series; rescheduled occurrence with event ledger row |

**Files:** `server/db/seeds/scenarios/health-care.js` (rewrite/expand), new `care-schedule-fixture.js` scenario, `docs/e2e/uat-demo-data.md` update, `server/test/seed.test.js` assertions.

---

## CSM-1 — Schema

Migration adding:

- `care_schedule_events` (ledger per §4 of verification spec)
- `health_occurrences.completion_timing`
- `health_entries.paused_since`, `health_entries.schedule_policy_version`
- `health_entries.status` accepts `paused` (no CHECK constraint today)

---

## CSM-2 — Module shell + anchor defaults

- `server/lib/care/schedule/` namespace
- `SCHEDULE_POLICY_VERSION` constant (align with CP/CIM versioning style)
- `defaultRecurrenceAnchor(careFamily)` → D-CSM-001
- Wire into `crudRouter` create (and update when anchor omitted)

**Dependency rule:** CSM must not import `care_intelligence`, `care_progression`, `care_context`, or `care_presentation`.

---

## CSM-3 — `advanceSeries()`

Single internal rollover: when all pending occurrences for the earliest open date are closed, compute next date via `advanceByFrequency` (anchor-aware). Removes all `addCalendarDaysIso(x, 1)` shortcuts in rollover paths.

**Tests:** `server/test/careSchedule/advanceSeries.test.js` — scenarios 1–6, 19 from verification list.

---

## CSM-4 — Remove pre-materialization

Remove `anchor + 1` batch in `materialiseInitialOccurrences` (D-CSM-004). Update `docs/domains/health_tracking/changes/occurrence-scheduling.md`.

---

## CSM-5 — `completeOccurrence`

- Closes occurrence; stores `completion_timing` at write time
- Calls `advanceSeries()`
- Weight monitoring: atomic `weight_entries` row (existing `complete-weight` path becomes sole route)

---

## CSM-6 — `skipOccurrence`

- Closes occurrence as skipped; writes `care_schedule_events`
- Replaces `POST /:id/occurrences/:occId/skip` and internalises `skip-missed` as repeated skips or batch helper

---

## CSM-7 — Retire legacy complete/skip paths

**Delete / stop writing (D-CSM-003):**

- `POST /:id/skip`, `POST /:id/unskip`
- `health_history` fallback in `mark-taken`
- No read-only archive — table stays until later drop migration

---

## CSM-8 — `undoLastAction`

Timestamp-aware undo across `health_occurrences` and `care_schedule_events`; retires split `undo-complete` / per-occurrence undo guessing.

---

## CSM-9 — `pauseSeries` / `resumeSeries`

- `health_entries.status = 'paused'`, `paused_since` cache
- Ledger events; resume with **no catch-up** (D-CSM-005)

---

## CSM-10 — `rescheduleOccurrence`

One-instance move; `scheduled_date` preserved on event row; series cadence untouched (D-CSM-006).

---

## CSM-11 — `adjustCadence`

Series-forward frequency/anchor change from `effective_from`; past occurrences immutable.

---

## CSM-12 — `projectSchedule`

Read-only refactor from `projectCareForPeriod`; per-item certainty (`complete` \| `conditional_on_future_completion`); aggregate status preserved for coverage policy.

---

## CSM-13 — `explainGap`

Read-only structured facts from `care_schedule_events` for CIM; CSM stays ignorant of explained/unexplained vocabulary.

---

## CSM-14 — Care Context thin caller

`carePeriodProjectionRouter` → `projectSchedule` only; 30-case corpus regression gate.

---

## CSM-15 — Flutter cleanup

- Remove `HealthEntriesNotifier.snooze()` and dashboard snooze wiring
- Route deferrals through server primitives when available (reschedule lands in CC UI tranche)

---

## CSM-17 — Integration gate (hard gate) — **shipped**

| Consumer | Regression |
|----------|------------|
| Care Context | Projection corpus identical |
| Care Progression | Weight establishment from occurrence-linked evidence only |
| CIM | `ruleEngine.js` unchanged for entries with no schedule events; pause/reschedule facts via `explainGap` covered in `explainGap.test.js` |

Regression suite: `server/test/careSchedule/integrationGate.test.js` (merged [#1192](https://github.com/KanopeeKa/AgathaCheck/pull/1192)).

---

## CSM-18 — Documentation

- Finalise [care-schedule-management.md](../features/care-schedule-management.md)
- Update `care-context.md`, `care-intelligence.md`, `care-progression.md`
- Deprecation notes for `health_history` and client `snooze()`
- Stale doc list: `occurrence-scheduling.md`, `api-reference.md`, `care-foundation-roadmap.md`

---

## Test layout

```
server/test/careSchedule/
  completeOccurrence.test.js
  skipOccurrence.test.js
  rescheduleOccurrence.test.js
  pauseResumeSeries.test.js
  adjustCadence.test.js
  advanceSeries.test.js
  projectSchedule.test.js
  explainGap.test.js
```

Minimum scenarios: verification review §10 items 1–18 plus additions 19–28 from planning review.

---

## Domain boundaries (read interfaces)

| Domain | Reads from CSM | Writes to CSM |
|--------|----------------|---------------|
| `care_context` | `projectSchedule` | — |
| `care_intelligence` | `explainGap` | — |
| `care_progression` | pause/resume events (filtered) | — |
| `care_presentation` | recent schedule events (copy) | — |
| `care_entitlements` | gates which primitives may run | — |

CSM must not depend on domains above it.
