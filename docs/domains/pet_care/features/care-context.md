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

## Related

- [care-through-change-delivery-plan.md](../changes/care-through-change-delivery-plan.md)
- [care-progression.md](care-progression.md) — domain map
- [care-entitlements.md](care-entitlements.md) — assistance gating principles
