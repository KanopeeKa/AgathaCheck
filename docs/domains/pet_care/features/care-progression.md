---
title: Care Progression
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_progression
status: active
related_prs: []
related_bdd: []
---

# Care Progression

Care Progression makes **meaningful care visible over time** without gamification. It recognises durable care continuity (**Established**) and meaningful care moments (**Milestones**).

**Programme delivery:** [care-progression-delivery-plan.md](/docs/domains/pet_care/changes/care-progression-delivery-plan.md)  
**Predecessor programme:** [Care Foundation roadmap](/docs/domains/pet_care/changes/care-foundation-roadmap.md) (Phases A–E)  
**Related:** [Care Intelligence](/docs/domains/pet_care/features/care-intelligence.md) · [Care entitlements](/docs/domains/pet_care/features/care-entitlements.md)

---

## Philosophy

> **Reward care, not attention.**

Care Progression must **not** introduce:

- XP, points, streaks, or global care scores
- Leaderboards or cross-pet comparison
- “Perfect week” mechanics or progress for opening the app
- Negative maturity states or punitive visuals
- Progress rings (excluded from V1; see Non-goals)

Absence of a progression marker is **neutral** — it must never imply a guardian failed to establish care.

---

## Purpose

| In scope (V1) | Out of scope (V1) |
|---------------|-------------------|
| Care maturity / **Established** markers (weight monitoring first) | Seasonal milestones or geography/climate modelling |
| Meaningful **Milestones** (small initial set) | Progress rings, care chapters, badge collections |
| Server-authoritative evaluation | Client-side maturity inference |
| Shared pet milestone history | Engagement optimisation |
| Quiet profile/dashboard moments | New Progress tab or progression feed |
| Care Rhythms inline Established markers | Generic observation-store migration |
| Timeline integration (late V1) | Paywall / entitlement implementation |
| | Partner/device integrations |
| | Consumption of CIM review-relevance output |

---

## Conceptual model

```text
                         CARE FAMILY
                  “What area of care is this?”
                              │
              ┌───────────────┴────────────────┐
              │                                │
              ▼                                ▼
        CARE ACTIONS                     CARE OBSERVATIONS
     “What care happens?”                “What was observed?”
              │                                │
      schedule / cadence                  numeric / ordinal
      recurrence                          value + unit
      completion                          observed time
      provenance                          source
              │                                │
              └───────────────┬────────────────┘
                              ▼
                         CARE RHYTHMS
                  recurring care over time
                              │
                              ▼
                     CARE MATURITY
                       “Established”
                              │
                              ▼
                         MILESTONES
                  meaningful care moments
```

**Layers, not competing taxonomies:**

| Layer | Question |
|-------|----------|
| Care events / observations | What happened or was measured? |
| Care Rhythms | What repeats? |
| Care Status | What needs attention now? |
| Care Progression | What has become established? What meaningful care happened? |
| Care Intelligence (CIM) | What has changed? What context matters for review? |

Care Progression must **not** alter deterministic Care Status because something is or is not Established.

---

## CareFamily as semantic anchor

`HealthEntryType` (medication / preventive / vet_visit / other) remains a **coarse operational type**.

`CareFamily` is the **stable semantic category** of care:

```text
medication
vaccination
parasite_prevention
wellness_review
dental
weight_monitoring
grooming
nail_care
other
```

Do **not** encode orthogonal concepts into family names (e.g. `monthly_weight`, `established_dental`). Keep recurrence, status, provenance, observations, and progression state separate.

### Write-path rule

Any care entry that participates in **Care Rhythms, Progression, Intelligence, or capability policy** must have an explicit, valid `care_family`.

- **Recurring entries** (`frequency != once`): `care_family` is **required** on write.
- **One-off entries**: explicit `care_family` preferred; type-based inference remains a compatibility fallback only.
- **Uncategorised**: use explicit `other` — not null.

Inference from `HealthEntryType` is a **defensive read fallback** during migration, not the normal write path for new data.

---

## Care-family capabilities

Capabilities are **code-defined policy** (not a DB catalog in V1). Example shape:

```text
CareFamilyCapabilities
  supportsCareEvents
  supportsRecurrence
  supportsObservations
  observationKind?
  supportsTrendView
  supportsEstablishment
  supportsMilestones
  speciesApplicability
  entitlementClass
```

Do not scatter `if (family == …)` across UI, routes, and services. Use a central capability registry on server and client (contract-tested).

### V1 capability matrix (initial ship)

| Care family | Establishment (V1 eval) | Milestones (V1) | Observations |
|-------------|-------------------------|-------------------|--------------|
| Weight monitoring | **Yes** | **Yes** | Numeric weight |
| Medication | Deferred | V1.1 (`course_completed`) | No |
| Vaccination | Architecturally supported; eval deferred | Deferred | No |
| Parasite prevention | Architecturally supported; eval deferred | Deferred | No |
| Wellness review | Architecturally supported; eval deferred | Deferred | No |
| Dental | Architecturally supported; eval deferred | Deferred | No |
| Grooming / nail care | Deferred | Deferred | No |
| Other | No by default | No by default | No by default |

Long-horizon families may be architecturally supported before calendar history or semantic data quality permits evaluation. **Silence** is correct until then.

---

## Observations (weight-first)

Weight uses specialised persistence (`weight_entries`), not generic health-entry notes.

**V1 direction:** specialised storage + shared domain interface (observation port). No generic `care_observations` table in V1.

### Weight rhythm → observation completion

```text
weight rhythm due
        ↓
guardian records actual weight
        ↓
weight observation created (weight_entries)
        +
rhythm occurrence completed (health_occurrences)
        linked via weight_entries.health_occurrence_id
```

Rules:

- A weight-rhythm occurrence is **not** completed without a real weight entry.
- Accepting an Agatha weight-rhythm suggestion creates the **rhythm only** — it does not invent an observation. The UI may offer “Record weight now” as a follow-up.
- **Standalone** weight entries (`health_occurrence_id = null`) remain allowed.
- **Skip** on a weight occurrence is allowed (existing occurrence model) but skipped occurrences **do not count** toward Establishment.

### Observation quality (shared primitives, separate policies)

```text
Shared primitives (care_observations)
  valid value, plausible value, valid timestamp
  trusted provenance, duplicate handling, unit consistency

CIM policy (care_intelligence)
  enough evidence for review relevance / safeguards

Progression policy (care_progression)
  enough linked valid observations + elapsed time + rhythm continuity
```

Progression must **not** consume Phase D review-relevance outputs. It may use shared observation-quality primitives, not CIM decision thresholds wholesale.

---

## Provenance (orthogonal concepts)

Do **not** overload `CareSource` on `health_entries`.

| Concept | Scope | Examples |
|---------|-------|----------|
| `CareSource` | Who/what **established the recurring care rhythm** | `guardian_defined`, `vet_instruction`, `agatha_accepted` |
| `measurementSource` | Where **this measurement** came from | `guardian`, `clinic`, `device`, `imported` |
| `referenceAuthority` | Who defines the **reference/target** | `vet_target`, `guardian_reference`, `historical_baseline` |
| `managementContext` | Is change **already intentionally managed** | `none`, `vet_managed`, `care_plan`, `treatment_related` |

Vocabulary aligns with the [Care Intelligence provenance model](/docs/domains/pet_care/features/care-intelligence.md) (see section **Provenance model**). Never infer one concept from another without explicit evidence.

---

## Terminology: “Established”

### Progression maturity (user-facing)

**Established** means:

> This recurring care has demonstrably become a stable part of this pet’s care over an appropriate period for that care family.

It is **not** a streak, health grade, or proof of clinical perfection.

**Visible copy:**

- Marker: **Established**
- Explanatory (milestones / moments): e.g. **“Part of Luna’s regular care.”**

### Retired uses of “established”

The codebase previously used “established” to mean **recurring care exists**. That meaning is retired in favour of:

| Old | New |
|-----|-----|
| `hasEstablishedRhythm()` | `hasActiveRecurringCare()` |
| “established care” (rhythm list) | “recurring care” / “active rhythm” |
| “established care configuration” | “care provenance” / “how this rhythm was set up” |

Only **Care Progression maturity** uses **Established** in user-facing progression copy.

---

## Established care semantics

### Family-specific, cadence-relative

There is no universal `3 completions = Established`.

Evaluation uses the **accepted or authoritative rhythm** (cadence, interval, provenance) plus valid linked evidence — not an independently chosen clinical ideal cadence.

Conceptual eligibility (policy-defined, versioned):

```text
active recurring care (care_family + rhythm)
+
valid observation history (where required)
+
minimum elapsed calendar span (cadence band)
+
sufficient expected occurrences completed with valid evidence
=
eligible for Established
```

Cadence bands (illustrative — final thresholds live in policy modules):

| Band | Example cadences | Intent |
|------|------------------|--------|
| High frequency | weekly, biweekly | Enough occurrences + several weeks |
| Medium | monthly-ish | Enough occurrences + several months |
| Low / annual | yearly+ | Architecturally supported; evaluation deferred in V1 |

### Visible states

```text
no marker  →  neutral (includes not evaluable, insufficient evidence, not yet eligible)
Established marker  →  only when confidently established
```

**Never** show: “not established”, grey uncertain states, or negative progression signals.

### Internal diagnostics (not product UI)

Evaluators may distinguish internally (logs/tests only):

```text
not_evaluable | insufficient_evidence | eligible_not_yet_established | established
```

Only the transition to **established** is persisted (see Persistence). Intermediate states are derived on read unless a future audit requirement emerges.

### Resilience

- One late or missed occurrence does **not** revoke Established.
- **Pause / end** rhythm: lifecycle state is separate from historical progression. Establishment achieved at time T **persists**; V1 does not introduce “lost Established status”.
- Re-establishment after a very long gap: deferred (future `establishmentEpoch`).

### Historical ambiguity = silence

If `care_family`, recurrence history, or completion evidence is ambiguous — **no marker**. Do not infer maturity from:

- legacy `mark-taken` without occurrence linkage
- `completed_on` on the series row alone
- inferred `care_family` with low confidence

Pre-production: prefer data cleanup and explicit write paths over guardian-facing legacy repair flows. Re-check launch status before destructive cleanup (see delivery plan CP-0).

### Weight-specific evidence (V1)

Establishment counts only:

```text
health_occurrence.status = 'completed'
AND weight_entries.health_occurrence_id = occurrence.id
AND observation passes progression quality primitives
```

Deleting a weight entry after establishment does **not** revoke establishment in V1 (documented limitation).

---

## Milestones

Milestones recognise **meaningful care**, not app activity.

### V1 milestone set (initial ship)

| Milestone | Scope | Identity |
|-----------|-------|----------|
| `first_care_established` | Pet-level once | `first_care_established` |
| `weight_monitoring_established` | Per pet + family | `weight_monitoring_established` |

**V1.1 (post initial ship):** `medication_course_completed` keyed to `health_entry_id`.

**Deferred:** `annual_wellness_review_completed`, `one_year_useful_weight_history`, engagement-style milestones.

### Shared pet history

Milestone **records** belong to the pet’s shared care history (visible to all authorised guardians).

### Combined presentation

When `first_care_established` and `weight_monitoring_established` are created in the same evaluation run:

- **Persist both** milestone rows.
- Show **one** combined moment anchored on the family milestone, with secondary acknowledgement of first care.

### Idempotency

Milestone generation must be **idempotent**. Recomputation (migration, backfill, policy change, background job) must not create duplicates or re-fire celebration.

- **Persistence identity:** server-side `dedupe_key` (unique per pet).
- **Presentation identity:** per-user `care_milestone_presentations` — each guardian may see the moment once; throttle applies to presentation, not persistence.

### Presentation throttle (V1)

Maximum **one prominent milestone moment per pet per guardian per ~30 days** (presentation only). Milestone records still persist. Safeguards **always** outrank milestone moments.

---

## Presentation

### Surfaces (V1)

| Surface | Role |
|---------|------|
| **Care Rhythms list** | Primary **Established** inline marker (secondary to due/current state) |
| **Pet profile** | Quiet progression summary; milestone moment via contextual slot |
| **Dashboard** | At most one meaningful progression moment; respects central arbitration |
| **Timeline** | Persistent milestone entries (late V1 — CP-7) |

No new Progress tab. No progression feed.

### Contextual card hierarchy

```text
ALWAYS / STRUCTURAL
  Care Status
  Care Rhythm rows
  Established inline markers (rhythms list)

CONTEXTUAL CARD SLOT (max one prominent card)
  1. Safeguard (CIM Phase E)
  2. Actionable Agatha suggestion
  3. Milestone moment
  4. Lower-priority contextual prompt
```

Established + overdue is **not contradictory** — they answer different questions. Do not combine into one status chip (e.g. avoid “Established · Time to Follow Up”). Due/current state remains the primary operational signal; Established is secondary context.

Centralise arbitration in `care_presentation` — not per-screen logic. Phase E may ship a minimal safeguard slot before full CP-6 consolidation.

---

## Server authority (invariant)

> **All progression truth is server-authoritative.**

| Server owns | Client may |
|-------------|------------|
| Establishment evaluation | Render results |
| Milestone eligibility + `dedupe_key` | Animate / defer presentation |
| Persisted transitions | Cache server DTOs |
| Policy version identifiers | Submit user actions (completion, etc.) |

| Client must not |
|-----------------|
| Independently compute Establishment |
| Create milestone identity or dedupe keys |
| Recompute progression maturity locally |

---

## Domain boundaries

CIM is the **intelligence module**, not the umbrella for all Pet Care logic.

```text
care_core           shared vocabulary, capabilities
care_planning       events, rhythms, occurrences, Care Status
care_observations   weight + quality primitives
care_progression    maturity, milestones
care_intelligence   suggestions, review relevance, safeguards
care_presentation   collision, slots, copy shaping
care_entitlements   access policy (future tiers)
```

**Dependency rules:**

- Progression reads Planning + Observations; **never** CIM.
- Planning never depends on Progression or CIM.
- Care Status never depends on Progression or CIM.
- Presentation consumes outputs; does not redefine them.

**Folder migration is incremental.** The domain map is normative; historical feature folders (`pet_profile`, `health_tracking`, `care_intelligence`) move gradually — see delivery plan.

---

## Relationship to Care Intelligence

| Concern | Owner |
|---------|-------|
| Suggested rhythms | CIM |
| Review relevance / safeguards | CIM |
| Established / milestones | Care Progression |
| Weight observation storage | care_observations |
| Weight series adequacy (primitive) | care_observations |
| Safeguard thresholds | CIM |
| Establishment thresholds | Care Progression |

If CIM were removed, AgathaTrack remains a coherent care-management product.

---

## Regulatory

Milestone and establishment persistence must be mapped in [DATA_MAP.md](/regulatory/DATA_MAP.md) before ship. No raw clinical diagnosis in progression copy.

---

## Delivery status

| Artifact | Role |
|----------|------|
| [care-progression-delivery-plan.md](/docs/domains/pet_care/changes/care-progression-delivery-plan.md) | CP-0–CP-7 sequencing, APIs, migrations, exit criteria |
| [care-entitlements.md](/docs/domains/pet_care/features/care-entitlements.md) | Future tier principles (no runtime in V1) |
| Future execute-plan `care-progression-*` | Created when implementation begins (after Phase E merge) |

Phase mechanics belong in the delivery plan, not in this document.
