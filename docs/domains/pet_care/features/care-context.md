---
title: Care Context
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_context
status: active
last_updated: 2026-10-07
related_prs: []
---

# Care Context

**Product programme:** Care Through Change (user-facing) · **Capability:** factual circumstances around care (planned absences, care-for-dates projection, away plan presentation).

## Summary / scope

- **Owns:** `planned_absences` facts; declarer-scoped absence CRUD; care-period **projection** and **coverage** read models; away hub/plan routes and presentation (`planned_care_items[]`, readiness facts, pre-absence attention); `explainGap` read contract for schedule facts during a window; absence UX (title, summary card, trip-details form).
- **Does not own:** occurrence commands, tick, or timing rules ([care-schedule-management.md](./care-schedule-management.md)); per-pet **carer** schema, handover PDF programme, invite flows ([away-planning-carer-model.md](./away-planning-carer-model.md)); per-item absence **resolutions** on the Care Item ([care-item-evolution.md](./care-item-evolution.md)); Care Planner write path (reschedule is CSM).
- **Depends on:** CSM `projectSchedule` / `explainGap`; pet home timezone ([calendar-dates.md](/docs/architecture/calendar-dates.md)); People carer candidates (write validation only — see carer model doc).

```text
Care Context ≠ Care Obligation
```

A declared absence does not create HealthEntries, alter Care Status, change recurrence, or imply medication is “at risk”. Recording an absence changes no care; only a person's explicit action does.

## Vocabulary

| Term | Meaning |
|------|---------|
| Planned absence | `planned_absences` row + `planned_absence_pets` join |
| Absence window `[S, E]` | `starts_on` … `ends_on` inclusive calendar days |
| Projection completeness | `complete` vs `partially_indeterminate` — whether all dates in the window are knowable |
| Coverage state | `CarePeriodCoveragePolicy` reassurance vocabulary (distinct from completeness) |
| `planned_care_items[]` | Server-sorted away-plan rows per pet (replaces legacy routine/dated/uncertainties split) |

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-CONTEXT-R-001 | Hard invariant: Care Context stores facts, not obligations; no care claims from context alone | Live |
| CARE-CONTEXT-R-002 | Care-period preview is `pet_id + starts_on + ends_on`; preview never auto-creates a planned-absence record | Live |
| CARE-CONTEXT-R-003 | `planned_absences`: `active` or `cancelled`; `ends_on >= starts_on`; request horizon max 12 months; optional `title` (max 60, trimmed); multi-pet via join table | Live |
| CARE-CONTEXT-R-004 | Overlapping active absences per pet allowed; non-blocking overlap warning on save (no 409 for overlap alone) | Live |
| CARE-CONTEXT-R-005 | Planned absences declarer-scoped in V1 — collaborators do not see each other's absences | Live |
| CARE-CONTEXT-R-006 | `title` on wire; display title primary, dates secondary; surfaces: hub tile, dashboard tile, plan summary, handover PDF, carer invite preview; Care Item Absence sections use date range only (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-007 | Plan page summary card (title, dates, notes preview) with local Edit; no app-bar edit or duplicate details blocks (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-008 | Full-screen trip details: title, dates, notes, delete (cancel); V1 edit excludes pets; date-change confirms cover carer window and plan review (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-009 | Create uses single CRUD form with inline care preview — not a step wizard (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-010 | Absence-wide notes labelled **Notes** (`handover_note`); per-pet notes stay in carer dialog (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-011 | Projection: `starts_on <= scheduled_date <= ends_on`; materialised occurrences win; default anchor `from_completion` → indeterminate tail; `projection_status` + `uncertainties[]` on wire | Live |
| CARE-CONTEXT-R-012 | `nothing_scheduled` only when projection `complete` and zero items; partially indeterminate forbids global reassurance (D-AWAY-002) | Live |
| CARE-CONTEXT-R-013 | Coverage states server-authoritative: `nothing_scheduled`, `all_completed`, `no_unresolved_items`, `has_items_to_review`; per pet, not global | Live |
| CARE-CONTEXT-R-014 | No absence pointer on projection APIs; schedule facts via `explainGap(entry, fromDate?, toDate?)` only (D-AWAY-011) | Live |
| CARE-CONTEXT-R-015 | Readiness: two facts at read time — carer coverage + care coverage — no single “prepared” verdict (D-AWAY-001, D-AWAY-002) | Live |
| CARE-CONTEXT-R-016 | Plan header readiness attention-only: carer line only when not all pets have carers; care line only for `has_items_to_review` or indeterminate (D-AWD-001); PDF keeps both lines | Live |
| CARE-CONTEXT-R-017 | `planned_care_items[]` one row per `health_entry_id` with `kind` discriminant; server sort; `items[]` flat list unchanged for counts/preview (D-AWD-002) | Live |
| CARE-CONTEXT-R-018 | Unified **Planned care** section; row tap → `/pet/:petId/events/:entryId` (D-AWD-004, D-AWD-005); pet header photo + profile link (D-AWD-006) | Live |
| CARE-CONTEXT-R-019 | Away plan row contract R-A1–R-A9: open/overdue/pre-window rules, date_basis labels, section footnote for estimates, PDF parity, paused rows (see § Away plan display) | Live |
| CARE-CONTEXT-R-020 | In-window list filter: include `in_window` rows; when `today >= S` include stale pre-`S` open work; exclude pre-window overdue while `today < S` (wire `pre_absence_overdue_attention`); PDF parity (CARE-CONTEXT-D-002) | Live |
| CARE-CONTEXT-R-021 | No **Plan this** on away plan; flexible rows use **See options** → care item detail; inline Care Planner block removed from plan (CARE-CONTEXT-D-002) | Live |
| CARE-CONTEXT-R-022 | Saving absence requires dates + pets only; carers, note, download optional (D-AWAY-010) | Live |

## Planned absence model

```text
planned_absences
  id, user_id, starts_on, ends_on, title?, provenance, source_ref?, status, timestamps

planned_absence_pets
  planned_absence_id, pet_id
```

Active absence: `status != cancelled` and `ends_on >= today`. Default list: non-cancelled with `ends_on >= today`, `starts_on ASC`.

**Provenance (Care Context namespace):** `user_declared` (V1 runtime); `calendar_import`, `integration_import`, `environmental_provider`, `system_derived` (future). Distinct from `CareSource` on health rhythms.

## Care-period projection

Owned by **care_planning**; Care Context is a thin caller to CSM `projectSchedule`. Scheduling semantics: [care-schedule-management.md](./care-schedule-management.md).

| Concept | V1 rule |
|---------|---------|
| Request horizon | Max 12 months ahead |
| Certainty horizon | Per rhythm — how far exact dates are knowable now |

**Completeness:** `projection_status: complete | partially_indeterminate` with `uncertainties: [{ health_entry_id, reason }]`. Zero projected items ≠ “nothing scheduled” when an active `from_completion` rhythm makes the window partially indeterminate.

**Worked examples:** (A) Monthly flea `from_due_date` in window → complete, items shown. (B) Daily meds `from_completion` with pending 14 Aug in trip 12–19 Aug → include 14 Aug; later in-window dates uncertain. (C) Pre-window pending `from_completion` with trip downstream → no items but rhythm contributes uncertainty — coverage must not return global `nothing_scheduled`.

## Coverage / reassurance policy

`CarePeriodCoveragePolicy` (`server/lib/care/carePeriodCoverage.js`) — separate from projection completeness. When `partially_indeterminate`: no global reassurance; may show known fixed items with calm qualifier copy. Multi-pet: *“Here’s care for each pet during those dates.”*

## Schedule facts (`explainGap`)

| Input | `entry`, optional `fromDate` / `toDate` (`YYYY-MM-DD`) |
| Output | `events[]` from `care_schedule_events` — facts only, no explained/unexplained vocabulary |

Reverse lookup (which absence overlapped an event): query `planned_absences` by `(user_id, date window)` — D-AWAY-011.

## UX surfaces

| Screen | Route |
|--------|-------|
| Away hub | `/pc/away` |
| Plan (read) | `/pc/away/:id` |
| Trip details (edit) | `/pc/away/:id/edit` — title, dates, notes, cancel |
| Create | `/pc/away/new` |

Per-pet coverage on the plan page: one request per pet (V1). Carer assignment UI: [away-planning-carer-model.md](./away-planning-carer-model.md).

## Away plan display (R-A1–R-A9)

Wire: `planned_care_items[]` with `open_occurrence`, `in_window`, `is_paused`, `date_basis` — server computes; Flutter renders ([api-reference.md](/docs/architecture/api-reference.md)).

| Req | Behaviour |
|-----|-----------|
| R-A2 | Icon, title (no `~`), recurrence line, then date lines (not legacy `"Next due date:"` when ACP fields present) |
| R-A3 | Open overdue or due before `S`: real date (+ time) + **Overdue** or **Due before you leave** |
| R-A4 | In-window: scheduled = date only; `planned` → "Planned: {date}"; `estimated` → "Estimated: {date}" |
| R-A5 | Multiple in-window dates: first, count, last — not one line per hop |
| R-A6 | One section footnote when any estimated date in section |
| R-A7 | `"Date not known"` only when no date computable — paused-only since D-ACP-011 (real occurrences) |
| R-A8 | PDF uses same copy as screen (`AwayPlanScheduleCopy`) |
| R-A9 | Paused: **Paused**, no dates |

**Absence ↔ schedule (D-ACP-011, D-CSM-028):** move after return → Postpone until day after return (`reason: absence`, `absence_id`); move before leaving → Change date; in-trip carer date → Plan another date + Looked after by on that occurrence.

## `planned_care_items[]` kinds (D-AWD-002)

| `kind` | Meaning |
|--------|---------|
| `recurring_calendar` | repeating, `from_due_date` |
| `recurring_chain` | repeating, `from_completion` |
| `single_once` | `frequency = once` |
| `indeterminate_pending` | paused item only |

Sort: kind bucket order → `name.localeCompare()`. Least-certain-wins among constituents (D-AWAY-006).

## Out of scope (V1)

Pet Sitting workflow, environmental context, calendar integrations, AI interpretation, proactive trip detection, arrangement fields (travelling with me / sitter), progression moments, entitlements runtime, editing pets on an existing absence.

**Pet Sitting boundary:** read-only care summary for dates = Pet Care; sending to a sitter with permissions = Pet Sitting (future).

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| CC-1 — When projection corpus case runs then Matches fixture expectations (31 cases) | CARE-CONTEXT-R-011 | test: server/test/careContext/carePeriodProjection.test.js |
| CC-2 — When coverage policy matrix cell then Evaluator returns expected state | CARE-CONTEXT-R-012 | test: server/test/careContext/carePeriodCoverage.test.js |
| CC-3 — When readiness triple (carer × coverage) then Tile and summaries agree | CARE-CONTEXT-R-015 | test: server/test/careContext/awayPlanReadiness.test.js |
| CC-4 — When overlap on save then Warning only; persist allowed | CARE-CONTEXT-R-004 | test: server/test/careContext/plannedAbsenceLib.test.js |
| CC-5 — When `buildPlannedCareItems` fixtures then One row per entry; kinds and sort | CARE-CONTEXT-R-017 | test: server/test/careSchedule/awayPlanPresentation.test.js |
| CC-6 — When in-window filter rules then Visibility matches CARE-CONTEXT-D-002 | CARE-CONTEXT-R-020 | test: server/test/careSchedule/plannedCareVisibility.test.js |
| CC-7 — When dashboard tile tapped then Away hub loads | CARE-CONTEXT-R-002 | bdd: away_planning.feature#Dashboard away planning tile opens the hub |
| CC-8 — When guardian saves create form then Absence appears on hub | CARE-CONTEXT-R-009 | bdd: away_planning.feature#Guardian can save a planned absence from the create form |
| CC-9 — When plan detail v2 scenarios then Unified list and edit route | CARE-CONTEXT-R-018 | test: e2e/playwright/tests/away.plan.detail.v2.spec.ts |
| CC-10 — When away care planning scenarios then Row labels and open occurrence visible | CARE-CONTEXT-R-019 | test: e2e/playwright/tests/away.care.planning.spec.ts |

Coverage gaps: [#1770](https://github.com/KanopeeKa/AgathaCheck/issues/1770) (absence title on all surfaces, overlap E2E, trip-details delete confirm).

## Still open

- D-AWAY-009 Part 2: honest “changed since download” when projection fingerprint exists.
- D-AWAY-012 residual copy migrations (care team / veterinary team) — track in terminology debt.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| D-AWAY-001 | No second absence “status” column | Only `active` / `cancelled`; facts computed at read time | Live | 2026-09-15 | AW |
| D-AWAY-002 | Readiness is two facts, not one verdict | Carer coverage + care coverage; `nothing_scheduled` never “everything covered” | Live | 2026-09-15 | AW |
| D-AWAY-006 | Collapsed rows use least-certain constituent | Any `conditional_on_future_completion` → `~` on grouped row | Live | 2026-09-15 | AW |
| D-AWAY-007 | Indeterminate care visible as named rows | Never silent omission; enriched `name`/`type`/`care_family` | Live | 2026-09-15 | AW |
| D-AWAY-010 | Save never requires complete plan | Dates + pets sufficient | Live | 2026-09-15 | AW |
| D-AWAY-011 | No absence pointer on projection; document `explainGap` | Avoid overloading `source_ref` | Live | 2026-09-15 | AW |
| D-AWD-001 | Plan-page readiness attention-only | Supersedes part of D-AWAY-002 presentation on header | Live | 2026-09-22 | AWD |
| D-AWD-002 | Group by `health_entry_id`; `planned_care_items[]` | Supersedes D-AWAY-006 grouping key | Live | 2026-09-22 | AWD |
| D-AWD-003 | Chain rows show interval description | Extends D-AWAY-007 | Live | 2026-09-22 | AWD |
| D-AWD-004 | One **Planned care** list | Retires Routine/Dated/Indeterminate headings | Live | 2026-09-22 | AWD |
| D-AWD-005 | Rows tap through to Care Item Detail | No new screen | Live | 2026-09-22 | AWD |
| D-AWD-006 | Pet header avatar + profile link | Reuse `CareEventRowPetAvatar` | Live | 2026-09-22 | AWD |
| D-AWD-007 | Notes-only edit route retired | Superseded by trip-details form (CARE-CONTEXT-D-001) | Superseded by CARE-CONTEXT-D-001 | 2026-09-22 | #1772 |
| CARE-CONTEXT-D-001 | Absence UX evolution: title, summary card, CRUD create, trip-details edit | Product programme absence-ux-evolution | Live | 2026-10-07 | #1772 |
| CARE-CONTEXT-D-002 | Away plan in-window filter; pre-departure overdue via profile link | Reduces plan noise; PDF parity with screen | Live | 2026-09-26 | scope-simplify |

Carer, handover, and programme decisions (D-AWAY-003–005, D-AWAY-008–009, D-AWAY-012–014): [away-planning-carer-model.md](./away-planning-carer-model.md). Display amendments D-ACP-*: [away-care-planning-decisions.md](../changes/away-care-planning-decisions.md).

## Related

| Kind | Link |
|------|------|
| Scheduling | [care-schedule-management.md](./care-schedule-management.md) |
| Care Item | [care-item-evolution.md](./care-item-evolution.md) |
| Carer / handover | [away-planning-carer-model.md](./away-planning-carer-model.md) |
| Away delivery (carer phases) | [away-planning-delivery-plan.md](../changes/away-planning-delivery-plan.md) |
| Progression | [care-progression.md](./care-progression.md) |
| API | [api-reference.md](/docs/architecture/api-reference.md) |
