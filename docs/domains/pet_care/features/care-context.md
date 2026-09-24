---
title: Care Context
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_context
status: active
related_prs: []
related_bdd: []
---

# Care Context

**Product programme:** Care Through Change (user-facing experience)  
**Domain capability:** Care Context (factual circumstances around care)

Care Context stores **facts**, not judgments. It must never create care obligations.

## Hard invariant

```text
Care Context ≠ Care Obligation
```

A declared absence does not create HealthEntries, alter Care Status, change recurrence, or imply medication is “at risk”.

## V1 scope — planned absence / away planning

> A pet parent can preview care scheduled during a date range (and optionally save the absence). AgathaTrack reassures only when projection completeness and care state support the claim.

### Preview before save

Care-period projection is a function of `pet_id + starts_on + ends_on`. Preview **never** auto-creates a planned-absence record. Saving requires an explicit user action.

**Preview itself is a complete user outcome.** Saving is only to keep context for later.

### Planned absence model

```text
planned_absences
  id, user_id, starts_on, ends_on, provenance, source_ref?, status, timestamps

planned_absence_pets
  planned_absence_id, pet_id
```

- One absence may attach multiple pets.
- `ends_on >= starts_on` (inclusive calendar dates).
- Request horizon: max **12 months**.
- Cancelled/past records persist; default list shows non-cancelled where `ends_on >= today`, ordered by `starts_on ASC`.

### Active absence (overlap warnings)

An absence is **active** when `status != cancelled` and `ends_on >= today` (calendar-date semantics).

Overlapping active absences for the same pet are **allowed**. On save, show a **non-blocking warning** naming conflicting date range(s); allow continue. No 409 solely for overlap.

### Shared-pet / privacy

- Care truth (projection) follows existing pet manage permissions.
- Personal absence context is **declarer-scoped** — collaborators do not see each other's planned absences in V1.

### Provenance (Care Context namespace)

```text
user_declared          # V1 runtime
calendar_import        # future
integration_import     # future
environmental_provider # future
system_derived         # future
```

Distinct from `CareSource` on health rhythms (`guardian_defined`, etc.).

## Care-period projection (Care Planning)

Owned by **care_planning**, not Care Context. Answers: “What existing care is scheduled in this window?”

**CSM dependency:** Projection logic refactors to `projectSchedule` in Care Schedule Management (CSM-12); Care Context remains a thin caller. Scheduling semantics (anchors, pause, materialisation): [care-schedule-management.md](./care-schedule-management.md).

### Request horizon vs certainty horizon

| Concept | V1 rule |
|---------|---------|
| **Request horizon** | Max 12 months ahead |
| **Certainty horizon** | Per rhythm — how far exact dates are knowable now |

Default recurrence anchor is `from_completion`. Future dates after an unresolved completion-dependent hop are **indeterminate** — not guessed.

### Projection completeness

```text
projection_status: complete | partially_indeterminate
uncertainties: [{ health_entry_id, reason }]
```

> Zero projected items ≠ “nothing scheduled” when an active `from_completion` rhythm makes the window partially indeterminate.

### Intersection

```text
starts_on <= scheduled_date <= ends_on  (inclusive)
```

Include **all** care families. Materialised `health_occurrences` rows win over simulated slots.

### Worked examples

**A — Safe (`from_due_date`):** Monthly flea due 5 Aug; trip 12–19 Aug → one fixed item; `projection_status: complete`.

**B — In-window hop:** Daily meds `from_completion`; pending occurrence 14 Aug; trip 12–19 Aug → include 14 Aug; later in-window dates uncertain; `partially_indeterminate`.

**C — Zero items but uncertain:** Pre-window pending `from_completion` occurrence; trip entirely downstream → **no items** but rhythm contributes uncertainty; coverage must **not** return global `nothing_scheduled`.

## Coverage / reassurance policy

Server-authoritative `CarePeriodCoveragePolicy` — separate from projection completeness.

| State | Meaning |
|-------|---------|
| `nothing_scheduled` | Only when projection `complete` and zero items |
| `all_completed` | Complete projection; all items completed (not skipped) |
| `no_unresolved_items` | Complete projection; terminal mix may include skips — neutral “nothing left to review”, never “care happened” |
| `has_items_to_review` | Pending/unresolved known items — neutral review, not alarm |

When `partially_indeterminate`: no global reassurance; may show known fixed items with calm qualifier copy.

## Multi-pet presentation (V1)

Projection and coverage are **per pet**. No global reassurance across pets. Top-level copy: *“Here’s care for each pet during those dates.”*

## Out of scope (V1)

Pet Sitting workflow, environmental context, calendar integrations, AI interpretation, proactive trip detection, arrangement fields (travelling with me / sitter), progression moments, entitlements runtime.

## Pet Sitting boundary

> Read-only care summary for dates = Pet Care. Sending to a sitter with permissions = Pet Sitting (future).

## Schedule facts (`explainGap`) — read contract

Care Context does **not** own scheduling. When structured pause/reschedule/skip context is needed beyond raw occurrences, read **`explainGap`** from [Care Schedule Management](care-schedule-management.md) (CSM-13).

| Input | Shape |
|-------|--------|
| `entry` | `health_entries` row |
| `fromDate`, `toDate` | Optional calendar window (`YYYY-MM-DD`) |

| Output | Shape |
|--------|--------|
| `events[]` | Facts from `care_schedule_events` — `event_type`, dates, anchors, `reason_code`, `policy_version`. **No** explained/unexplained vocabulary (CIM owns interpretation). |

**No absence pointer on projection calls.** `planned_absences.source_ref` means what declared the absence externally. Which absence overlapped a schedule event is answerable from `planned_absences` by `(user_id, date window)` — see D-AWAY-011.

## Away Planning V1

Hub at `/pc/away`, plan page at `/pc/away/:id`, wizard at `/pc/away/new`, per-pet [carer model](./away-planning-carer-model.md), server-derived readiness (two facts), printable handover (AW-9). Per-pet coverage on the plan page issues **one request per pet** (acceptable V1; not a bug).

## Away Plan Detail V2 (plan page + edit screen)

Shipped on the integration branch as AWD-1–AWD-5. Canonical decisions: [away-plan-detail-v2-decisions.md](../changes/away-plan-detail-v2-decisions.md).

### Routes

| Screen | Route | Notes |
|--------|-------|-------|
| Hub | `/pc/away` | unchanged |
| Plan (read-only display) | `/pc/away/:id` | carer assignment stays inline; handover note read-only when present |
| Edit | `/pc/away/:id/edit` | handover note + delete (cancel) only — no dates/pets editing |
| Wizard (create) | `/pc/away/new` | unchanged |

### Attention-only coverage header (D-AWD-001)

On the plan page header (`AwayPlanHeaderSection`), server-derived readiness is **attention-only**:

- **Carer coverage** line renders only when `readiness.carer_coverage.state != all_have_carers`.
- **Care coverage** line renders only when `readiness.care_coverage.coverage_state` is `has_items_to_review` or `indeterminate`.

Reassuring states (`nothing_scheduled`, `all_completed`, `no_unresolved_items`) render **no** care-coverage line — the per-pet Planned care cards below already carry that detail. The handover PDF keeps both lines unconditionally (reader has no “fields below”).

### Unified planned care list (D-AWD-002–005)

Care-period projection and coverage responses expose a single server-sorted array per pet, **`planned_care_items[]`**, replacing the pre-V2 `routine_items` / `dated_items` / `uncertainties` split (breaking wire change — not versioned alongside; see [api-reference.md](/docs/architecture/api-reference.md)).

Each row is one `health_entry_id` with a `kind` discriminant:

| `kind` | Meaning |
|--------|---------|
| `recurring_calendar` | repeating, `recurrence_anchor = from_due_date` |
| `recurring_chain` | repeating, `recurrence_anchor = from_completion` |
| `single_once` | `frequency = once`, one row per occurrence |
| `indeterminate_pending` | no materialised date in the window yet |

The plan page shows one **“Planned care”** section per pet (server sort order; no client merge). Rows are tappable → existing Care Item Detail route (`/pet/:petId/events/:entryId`). Pet header shows photo + tap-through to pet profile.

Raw per-occurrence `items[]` stays on the wire unchanged for coverage counts and create-flow preview; only the three legacy grouped arrays were removed.

## Away care planning display (ACP — R-A*)

Shipped on the integration branch as ACP-1–ACP-3. Canonical decisions: [away-care-planning-decisions.md](../changes/away-care-planning-decisions.md) (D-ACP-001 … D-ACP-010). Delivery: [away-care-planning-delivery-plan.md](../changes/away-care-planning-delivery-plan.md).

### Row contract (per pet, per absence)

| Req | Behaviour |
|-----|-----------|
| **R-A1** | Every active, non-paused item with an overdue open occurrence, an open occurrence due before absence start `S`, or any scheduled/planned/estimated occurrence in `[S, E]` appears on the plan. |
| **R-A2** | Row shows care-family icon, title (**no** `~` prefix), recurrence line (D-AWD-003), then date lines below — not legacy `"Next due date:"` when ACP fields are present (R-A2.1). |
| **R-A3** | Open occurrence overdue or due before `S`: real date (+ time when set) with suffix **Overdue** or **Due before you leave** (same treatment as event list). |
| **R-A4** | In-window dates labelled by `date_basis`: scheduled = date only; `planned` → "Planned: {date}"; `estimated` → "Estimated: {date}" (D-ACP-002/003). |
| **R-A5** | Multiple in-window dates: first date, count, and last date (`first_scheduled_date` / `last_scheduled_date` / `occurrence_count`) — not one line per hop. |
| **R-A6** | When any row in a pet section shows an estimated date, one section footnote: estimates assume overdue care is completed today, then the usual interval. Suppresses `awayPlanningChainAnchorExplainer` for that section (R-A6.1). |
| **R-A7** | `"Date not known"` (`indeterminate_pending`) only when no date can be computed (D-ACP-001). |
| **R-A8** | PDF handover uses the same copy as the screen (`AwayPlanScheduleCopy`). |
| **R-A9** | Paused series: **Paused**, no dates (D-CSM-005). |

Wire fields on `planned_care_items[]`: `open_occurrence`, `in_window`, `is_paused` (see [api-reference.md](/docs/architecture/api-reference.md)). Server computes status and bases; Flutter renders only.

### Care Planner suggestions (R-D*)

Deterministic read model in `server/lib/care/planner/` (D-ACP-008). **Does not** write schedule state and **does not** feed Care Status, readiness, coverage, or Actions (R-D5).

| Req | Behaviour |
|-----|-----------|
| **R-D1** | **Suggested by Agatha** block lists moves that reduce in-window occurrences, each with from → to and a one-line reason. |
| **R-D2** | **Accept** runs `POST …/reschedule` with `reason_code: away_planner`; **Not now** hides for the session only (v1, not persisted). |
| **R-D3** | Summarises remaining carer work: "{n} care task(s) for your carer during this absence." |
| **R-D4** | Respects `schedule_flexibility` strictly (never `fixed` / `carer_task`; `earlier_only` → earlier only; within `max_shift_days`; not before today or inside `[S, E]`). |
| **R-D5** | Unaccepted suggestions never change coverage or readiness. |
| **R-D6** | No empty state when there is nothing to suggest — block omitted entirely. |

Placement: under the pet header, **above** "Planned care". `GET /api/planned-absences/:id/care-plan` (declarer-scoped). Overdue open occurrences during an **in-progress** absence show on the plan (R-A3) but get **no** planner suggestion in v1 (BR-7).

### Reschedule from care item (R-C*)

Care Item Detail and away-plan **Plan this** open the same **Change date** sheet (ACP-5). Server validation, `warnings[]`, and `next_due_date` sync are owned by CSM (D-ACP-009) — see [care-schedule-management.md](care-schedule-management.md).

## Related

- [care-schedule-management.md](care-schedule-management.md) — authoritative scheduling core (`projectSchedule`, `explainGap`)
- [away-planning-carer-model.md](./away-planning-carer-model.md) — per-pet carer schema and API
- [away-planning-delivery-plan.md](../changes/away-planning-delivery-plan.md)
- [away-planning-decisions.md](../changes/away-planning-decisions.md)
- [care-through-change-delivery-plan.md](../changes/care-through-change-delivery-plan.md)
- [care-progression.md](care-progression.md) — domain map
- [care-entitlements.md](care-entitlements.md) — assistance gating principles
