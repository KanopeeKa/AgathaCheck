---
title: Care Context
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_context
status: active
last_updated: 2026-11-04
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
| CARE-CONTEXT-R-005 | Planned absences declarer-scoped in V1 — collaborators do not see each other's absences (superseded by CARE-CONTEXT-R-032) | Retired |
| CARE-CONTEXT-R-006 | `title` on wire; display title primary, dates secondary; surfaces: hub tile, dashboard tile, plan summary, handover PDF, carer invite preview; Care Item Absence sections use date range only (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-007 | Absence screen summary card (title, dates, who's away, notes preview) with local Edit → trip details; per-pet away plan shows read-only trip header and **See absence** (CARE-CONTEXT-D-001, D-015) | Live |
| CARE-CONTEXT-R-008 | Full-screen trip details: title, dates, notes, delete (cancel); add/remove pets via absence and away-plan flows (R-033–R-035); date-change confirms cover carer window and plan review (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-009 | Create uses single CRUD form with inline care **reassurance** only (no care/date enumeration before save) — not a step wizard (CARE-CONTEXT-D-001, D-004) | Live |
| CARE-CONTEXT-R-010 | Absence-wide notes labelled **Notes** (`handover_note`); per-pet notes stay in carer dialog (CARE-CONTEXT-D-001) | Live |
| CARE-CONTEXT-R-011 | Projection: `starts_on <= scheduled_date <= ends_on`; materialised occurrences win; default anchor `from_completion` → indeterminate tail; `projection_status` + `uncertainties[]` on wire | Live |
| CARE-CONTEXT-R-012 | `nothing_scheduled` only when projection `complete` and zero items; partially indeterminate forbids global reassurance (D-AWAY-002) | Live |
| CARE-CONTEXT-R-013 | Coverage states server-authoritative: `nothing_scheduled`, `all_completed`, `no_unresolved_items`, `has_items_to_review`; per pet, not global | Live |
| CARE-CONTEXT-R-014 | No absence pointer on projection APIs; schedule facts via `explainGap(entry, fromDate?, toDate?)` only (D-AWAY-011) | Live |
| CARE-CONTEXT-R-015 | Readiness: two facts at read time — carer coverage + care coverage — no single “prepared” verdict (D-AWAY-001, D-AWAY-002) | Live |
| CARE-CONTEXT-R-016 | Absence screen attention-only combined status across pets the viewer can access (carer line when not all have carers; care line for `has_items_to_review` or indeterminate); away plan header shows per-pet facts (D-AWD-001, D-AWAY-002); PDF keeps both lines | Live |
| CARE-CONTEXT-R-017 | `planned_care_items[]` one row per `health_entry_id` with `kind` discriminant; server sort; `items[]` for projection only — away UI counts use care items (`review_queue` / `review_care_item_count`, D-005) (D-AWD-002) | Live |
| CARE-CONTEXT-R-018 | Unified **Planned care** section; row tap → `/pet/:petId/events/:entryId` (D-AWD-004, D-AWD-005); pet header photo + profile link (D-AWD-006) | Live |
| CARE-CONTEXT-R-019 | Away plan row contract R-A1–R-A9: open/overdue/pre-window rules, date_basis labels, section footnote for estimates, PDF parity, paused rows (see § Away plan display) | Live |
| CARE-CONTEXT-R-020 | In-window list filter: include `in_window` rows; when `today >= S` include stale pre-`S` open work; exclude pre-window overdue while `today < S` (wire `pre_absence_overdue_attention`); PDF parity (CARE-CONTEXT-D-002) | Live |
| CARE-CONTEXT-R-021 | No **Plan this** on away plan; flexible rows use **See options** → care item detail; inline Care Planner block removed from plan (CARE-CONTEXT-D-002) | Live |
| CARE-CONTEXT-R-022 | Saving absence requires dates + pets only; carers, note, download optional (D-AWAY-010) | Live |
| CARE-CONTEXT-R-023 | Saved plan: per-pet **Care to review** queue (care-item cards: title, in-trip impacted date count, Review dates, opt-in bulk select) before full schedule (D-004…D-009) | Live |
| CARE-CONTEXT-R-024 | Optional `planned_absence_id` on care-period coverage loads `review_queue[]` and care-item review counts | Live |
| CARE-CONTEXT-R-025 | **Absence** wraps the trip (title, dates, who is going away, trip-wide notes); each pet on it has one **away plan** (carer, notes for the pet, care to review, planned care); an absence has at least one away plan, one per pet (CARE-CONTEXT-D-011) | Live |
| CARE-CONTEXT-R-026 | Who is going away is the person who logs the absence — one person, not editable; shown as "You're away" / "{Name} is away" (CARE-CONTEXT-D-012) | Live |
| CARE-CONTEXT-R-027 | Create form: title, dates, pets, trip notes; ticking N pets creates N away plans; save lands on the absence screen, or on the pet's away plan when exactly one pet; opening from a pet pre-ticks it (CARE-CONTEXT-D-015) | Live |
| CARE-CONTEXT-R-028 | Absence screen `/pc/away/:id`: summary card, combined attention line, one pill per accessible pet ("See {Pet}'s away plan" + one-line status), Add a pet, full-trip PDF; per-pet content not duplicated | Live |
| CARE-CONTEXT-R-029 | Away plan screen: read-only trip header with See absence; pet header; Who's caring; notes for the pet inline; trip notes read-only; Care to review and Planned care for this pet; per-pet PDF; Remove pet | Live |
| CARE-CONTEXT-R-030 | Away plan route `/pc/away/:id/pets/:petId`; pushed full screen on mobile and web; Back follows origin via return path; See absence opens the absence screen | Live |
| CARE-CONTEXT-R-031 | Pet page section above "People around {Pet}": current and upcoming away plans for that pet, soonest first, max two + All absences; hidden when none or viewer not allowed; Plan an absence in the pet actions menu (Full access) | Live |
| CARE-CONTEXT-R-032 | Away plans visible to the person going away and anyone with Full access to that pet; Full-access viewers may edit that pet's carer and `pet_note` on a non-cancelled absence via `PATCH /:id/pets/:petId`; trip fields, add/remove pets, cancel, and declarer `PATCH /:id` stay declarer-only; absence screens show only accessible pets and never disclose others; Can log care and absence guests unchanged; access evaluated at read time; supersedes CARE-CONTEXT-R-005 (CARE-CONTEXT-D-013) | Live |
| CARE-CONTEXT-R-033 | Trip fields (title, dates, trip notes), delete, and add/remove pets are for the person going away only; adding a pet also needs Full access to it | Live |
| CARE-CONTEXT-R-034 | Pets can be added to a saved absence: new empty away plan; non-blocking overlap warning; existing guest carers gain no access to the new pet without confirmation (PEOPLE D16); supersedes pet-edit exclusion on CARE-CONTEXT-R-008 (CARE-CONTEXT-D-014) | Live |
| CARE-CONTEXT-R-035 | Removing a pet removes its carer, notes and trip decisions, ends its absence access and trims pending invites; care item dates unchanged; removing the last pet deletes the absence after an explicit confirmation (CARE-CONTEXT-D-014) | Live |
| CARE-CONTEXT-R-036 | Pet deletion removes its away plans and deletes an absence left with no pets; pet household moves or transfers keep the plan with the pet and re-evaluate visibility | Live |
| CARE-CONTEXT-R-037 | Per-pet status facts (carer state, care coverage, review count) on pill, pet page row and away plan header; carer gap first, then review count; absence-level combined facts unchanged (D-AWAY-002) | Live |
| CARE-CONTEXT-R-038 | Pet-specific links (care item absence module, pet overlap warnings) open that pet's away plan; hub and dashboard tile open the absence | Live |
| CARE-CONTEXT-R-039 | Away hub lists absences the viewer logged and absences including a pet the viewer has Full access to (labelled with who is away, accessible pets only); dashboard away tile stays the person going away's own | Live |
| CARE-CONTEXT-R-040 | Full-trip handover PDF covers only pets the downloader can access; per-pet PDF rules unchanged (AWAY-PLANNING-CARER-R-009, R-010) | Live |
| CARE-CONTEXT-R-041 | Care item absence module visible to Full-access viewers of the pet, consistent with CARE-CONTEXT-R-032 | Live |

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

An absence is **active** when `status != cancelled` and `ends_on >= today` (calendar-date semantics). **`today`** for list/upcoming filters and health-entry absence-context queries is the declarer's account IANA timezone (`users.timezone`), not server UTC. Away-plan care projections use each pet's `home_timezone` for schedule "today" (same as CSM open/overdue).

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
| Away hub | `/pc/away` — **Your absences** / **Other people's absences** |
| Absence (trip) | `/pc/away/:id` — summary, pills, Add pet, full-trip PDF |
| Per-pet away plan | `/pc/away/:id/pets/:petId` — carer, notes, care sections, per-pet PDF |
| Trip details (edit) | `/pc/away/:id/edit` — title, dates, notes, cancel (declarer only) |
| Create | `/pc/away/new` |

Per-pet away plan loads one coverage/projection request per pet. Carer assignment UI: [away-planning-carer-model.md](./away-planning-carer-model.md).

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

Pet Sitting workflow, environmental context, calendar integrations, AI interpretation, proactive trip detection, arrangement fields (travelling with me / sitter), progression moments, entitlements runtime, notifying co-parents when an absence that includes their pet is created or edited.

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
| AP-1 — Given three pets ticked, when the absence is saved, then one absence and three away plans exist and the absence screen shows three pills | CARE-CONTEXT-R-025, CARE-CONTEXT-R-027, CARE-CONTEXT-R-028 | test: flutter_app/test/features/pet_care/context/planned_absence_plan_screen_test.dart#absence screen shows pet pill without multi-pet care sections |
| AP-2 — Given one pet ticked, when saved, then the person lands on that pet's away plan screen | CARE-CONTEXT-R-027 | test: flutter_app/test/core/router/guardian_routes_test.dart#petCarePetAwayPlan resolves to /pc/away/:id/pets/:petId |
| AP-3 — When a pill is tapped, then the away plan screen shows only that pet's carer, notes, care to review and planned care; trip fields are read-only; See absence returns to the absence | CARE-CONTEXT-R-029, CARE-CONTEXT-R-030 | test: flutter_app/test/features/pet_care/context/pet_away_plan_screen_test.dart#pet away plan shows carer, notes, and planned care |
| AP-4 — Given the person logging, then "You're away" is shown and no traveller picker exists; others see "{Name} is away" | CARE-CONTEXT-R-026 | none — #1770 |
| AP-5 — Given an upcoming away plan for Buddy, when Buddy's page opens, then the section shows above People around Buddy and opens Buddy's plan; given none, the section is absent | CARE-CONTEXT-R-031 | none — #1770 |
| AP-6 — Given Sam has Full access to Buddy only, when Sam opens the absence, then only Buddy's pill shows and other pets are not disclosed; Sam can edit Buddy's carer and notes but not trip fields | CARE-CONTEXT-R-032, CARE-CONTEXT-R-033 | test: server/test/careContext/plannedAbsenceVisibility.test.js#GET /api/planned-absences/:id omits inaccessible pets for co-parent viewer |
| AP-7 — Given Can log care on Buddy, then no away plan section or screen is available | CARE-CONTEXT-R-032 | test: server/test/care/absence/loadHealthEntryAbsenceContext.test.js#returns empty absences when viewer lacks Full access to the pet |
| AP-8 — When a pet is added to a saved absence, then a new empty plan exists, overlap warns, and existing guest carers get no access without confirmation | CARE-CONTEXT-R-034 | test: server/test/careContext/plannedAbsencePetLifecycle.test.js#POST /:id/pets adds pet with overlap warnings |
| AP-9 — When a pet is removed, then its carer, notes and decisions for this trip go, its absence access ends, and care item dates are unchanged | CARE-CONTEXT-R-035 | test: server/test/careContext/plannedAbsencePetLifecycle.test.js#DELETE /:id/pets/:petId cancels absence when last pet confirmed |
| AP-10 — When the last pet is removed, then the confirmation states the absence will be deleted and the absence is deleted | CARE-CONTEXT-R-035 | test: server/test/careContext/plannedAbsencePetLifecycle.test.js#DELETE /:id/pets/:petId requires confirm when last pet |
| AP-11 — When a pet on a one-pet absence is deleted, then the absence is deleted | CARE-CONTEXT-R-036 | none — #1770 |
| AP-12 — Pill and pet-page status show carer gap first, then review count | CARE-CONTEXT-R-037 | test: flutter_app/test/features/pet_care/context/planned_absence_plan_screen_test.dart#absence screen shows pet pill without multi-pet care sections |
| AP-13 — From a care item's absence module, the link opens that pet's away plan | CARE-CONTEXT-R-038 | test: e2e/playwright/tests/care.item.absence.spec.ts |
| AP-14 — Hub lists absences including a pet the viewer has Full access to, labelled with the traveller | CARE-CONTEXT-R-039 | test: flutter_app/test/features/pet_care/context/planned_absence_hub_screen_test.dart#ownership sections |
| AP-15 — Full-trip PDF by Sam contains Buddy only | CARE-CONTEXT-R-040 | none — #1770 |

Coverage gaps: [#1770](https://github.com/KanopeeKa/AgathaCheck/issues/1770) (absence title on all surfaces, overlap E2E, trip-details delete confirm, co-parent PDF scope, multi-pet invite UX).

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
| CC-UI-D-001 | Away surfaces use away-context plum aliases, not Agatha teal or warm accent | User-declared trip vs Agatha suggestions | Live | 2026-10-08 | |
| CARE-CONTEXT-D-017 | Per-pet carer writes split actor vs traveller; co-parent private contact notes never copied to `carer_note` | `resolveCarerWrite` uses actor for directory/usability and traveller for "never a carer"; `PATCH /:id/pets/:petId` for Full access | Live | 2026-11-06 | away-plans co-parent fix |

Carer, handover, and programme decisions (D-AWAY-003–005, D-AWAY-008–009, D-AWAY-012–014): [away-planning-carer-model.md](./away-planning-carer-model.md). Display amendments D-ACP-*: [away-care-planning-decisions.md](../changes/away-care-planning-decisions.md).

## Presentation (Flutter)

Away planning chrome uses **away-context** plum tokens (`docs/design/tokens.md` § Away planning context), shared `AwayContextIconChip`, and **not** Agatha message teal or coral warm accent.

| Surface | Chrome |
|---------|--------|
| Dashboard `PlannedAbsenceEntryTile`, hub cards, hub empty state | `AwayContextIconChip` (`event_busy_outlined`) |
| Care-item absence modules | `flight_takeoff_outlined` + `awayContextAccent` |
| Away planner “Suggested by Agatha” heading | `awayContextAccent` (plum; distinct from inbox/profile Agatha cards) |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CC-UI-D-001 | Away surfaces use away-context plum aliases, not Agatha teal or warm accent | User-declared trip vs Agatha suggestions | Live | 2026-10-08 | |
| CARE-CONTEXT-D-017 | Per-pet carer writes split actor vs traveller; co-parent private contact notes never copied to `carer_note` | `resolveCarerWrite` uses actor for directory/usability and traveller for "never a carer"; `PATCH /:id/pets/:petId` for Full access | Live | 2026-11-06 | away-plans co-parent fix |
| CARE-CONTEXT-D-003 | Declarer `todayIso` once per absence request; pet access before declarer TZ on care-period preview; undo audit uses undo result occurrence id | Programme 9100 phase 2 | Live | 2026-10-13 | |
| CARE-CONTEXT-D-004 | No care/date enumeration on create before save; reassurance only | Away plan care review UX | Live | 2026-10-18 | |
| CARE-CONTEXT-D-005 | Away “to review” counts = unresolved affected care items, not `items[]` rows | D-005 | Live | 2026-10-18 | |
| CARE-CONTEXT-D-006 | Card impacted date count = in-trip pending dates only | D-006 | Live | 2026-10-18 | |
| CARE-CONTEXT-D-007 | Review dates → care item with absence review entry | D-007 | Live | 2026-10-18 | |
| CARE-CONTEXT-D-008 | Opt-in bulk mode; Select all/Clear; V1 bulk **Keep with carer** only (amendment approved 2026-10-18) | D-008 | Live | 2026-10-18 | |
| CARE-CONTEXT-D-009 | Review queue before schedule; **All planned care** collapsed when queue non-empty | D-009 | Live | 2026-10-18 | |
| CARE-CONTEXT-D-010 | Retire in-delivery doc `changes/away-plan-care-review-delivery-plan.md` after D-004–D-009 folded here | canonical-docs fold | Live | 2026-10-19 | |
| CARE-CONTEXT-D-011 | An absence wraps per-pet away plans (one pet each) instead of one multi-pet plan | Long multi-pet page mixed carers' information; facts are already per pet; gives the pet page a home for its absence | Live | 2026-11-03 | — |
| CARE-CONTEXT-D-012 | Who is going away = the person logging the absence; one traveller only for now | Avoids a traveller picker and multi-person rules; traveller is never a carer on their own absence | Live | 2026-11-03 | — |
| CARE-CONTEXT-D-013 | Anyone with Full access to a pet sees and edits its away plan; other pets on the absence are not disclosed | PEOPLE D17 (plans belong to the pet); pet page section must be coherent for co-parents; same privacy spirit as AWAY-PLANNING-CARER-D-014 | Live | 2026-11-03 | — |
| CARE-CONTEXT-D-014 | Pets can be added to and removed from a saved absence in this phase; removing the last pet deletes the absence | Per-pet plans make add/remove natural; an absence never exists with no plan | Live | 2026-11-03 | — |
| CARE-CONTEXT-D-015 | After save, land on the absence screen; on the pet's away plan when only one pet; naming Absence / {Pet}'s away plan (FR Absence / Plan d'absence de {Pet}) | Shortest path for single-pet trips; one locked vocabulary | Live | 2026-11-03 | — |
| CARE-CONTEXT-D-016 | Server away-plan visibility: Full-access reads filter pets; hub co-visible list; health-entry absence context; trip writes stay declarer-only | absence-per-pet-away-plans execute-plan | Live | 2026-11-03 | #2045 |

## Related

| Kind | Link |
|------|------|
| Scheduling | [care-schedule-management.md](./care-schedule-management.md) |
| Care Item | [care-item-evolution.md](./care-item-evolution.md) |
| Carer / handover | [away-planning-carer-model.md](./away-planning-carer-model.md) |
| Away delivery (carer phases) | [away-planning-delivery-plan.md](../changes/away-planning-delivery-plan.md) |
| Progression | [care-progression.md](./care-progression.md) |
| API | [api-reference.md](/docs/architecture/api-reference.md) |
