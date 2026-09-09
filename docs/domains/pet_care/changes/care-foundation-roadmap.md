---
title: Care Foundation & Intelligence Roadmap
owner: Product / Documentation
audience: both
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, roadmap, implementation]
supersedes: AgathaTrack CIM Implementation Spec v0.1 (2026-09-07 upload)
---

# Care Foundation & Intelligence Roadmap

**Version:** 0.4 (review-relevance)  
**Target:** Pet Care domain only  
**Initial Agatha Suggestions species scope:** cats and dogs  
**Internal working name:** CIM — Care Intelligence Model  
**User-facing intelligence name:** Agatha / “Suggested by Agatha”  
**Codebase reference:** AgathaTrack `main` — Pet Care MVP (Shelter/Fostering frozen)

---

## 0. How to use this document

This document is the **active implementation roadmap** for Pet Care care organisation and, later, Care Intelligence.

It **supersedes** *AgathaTrack Care Intelligence (CIM) Implementation Spec — Draft v0.1* for sequencing, scope, and handoff to engineering agents.

### What this document is

| Section | Purpose |
|---------|---------|
| **Phases A–C** | Active implementation spec — build in order **without pausing for permission between phases** |
| **Phase D** | Review relevance — weight-first, internal-only; see [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) |
| **Phase E** | Guardian safeguards when evidence supports; see [care-intelligence.md](../features/care-intelligence.md) |
| **Vision appendix** | Product direction and future surfaces — **not** permission to implement |
| **Architecture reference** | Stable boundaries that span all phases |

### What Cursor must not do

- Treat the vision appendix or deferred roadmap as an implementation brief
- Skip Care Rhythms and jump to Agatha Suggestions
- **Start Phase D runtime work before D0.5 governance approval** (see [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md))
- Commit to fuzzy inference before crisp-rule evaluation completes (Phase D)
- Ship production safeguards before data-quality and clinical review criteria are met (Phase E)
- Redesign unrelated Pet Care features or reintroduce Shelter/Fostering dependencies
- **Pause between Phases A, B, or C to ask for permission** — complete each phase's definition of done, then proceed

Stay consistent with existing Flutter + Riverpod, repository/use-case patterns, GoRouter, recurrence infrastructure, notification infrastructure, design tokens, and responsive shell.

---

## 1. Product direction

AgathaTrack is focused first on **personal pet care**.

Near-term priority:

1. Pet Care — organise, understand, remember
2. Shared care / pet sitting later
3. Shelter / Rescue may be revisited much later

The emerging proposition:

> **AgathaTrack helps people organise, understand, remember and share the care of the animals in their lives.**

Care Intelligence belongs to **understand** and **remember**, but only after **organise** is trustworthy.

---

## 2. Product philosophy (non-negotiable)

CIM must **not** make AgathaTrack feel like an AI application.

It should feel like:

> **Agatha occasionally notices something useful, explains why, and lets the guardian decide what to do.**

Core principles:

| Principle | Meaning |
|-----------|---------|
| Rewards care, not attention | No engagement optimisation |
| AI can recommend care; it cannot define good care | Guardian and vet remain authoritative |
| Essential care is not premium | Safety-relevant core warnings must not be paywalled |
| Silence over false confidence | When uncertain, say nothing |
| Every meaningful recommendation must be explainable | No black-box scores in UI |

### Explicitly not building

Diagnosis, disease prediction, emergency chatbot, treatment/dosage recommendation, AI chat, generic web retrieval during recommendation generation, health scores, XP/coins/streaks, dedicated CIM/AI navigation tab.

### Quietness is intentional

If the app says **All Set** most of the time and surfaces a genuinely useful suggestion twice a year, that builds trust. Do not make CIM louder to justify engineering cost. Each layer must demonstrably improve care organisation or confidence — otherwise do not build it.

---

## 3. Implementation phases (summary)

```text
Phase A — Care Foundation
        ↓  (continue — no permission pause)
Phase B — Care Rhythms
        ↓  (continue — no permission pause)
Phase C — Suggested by Agatha (crisp rules only)  ✅ shipped on integration branch
        ↓
Phase D — Review Relevance (weight-first, internal-only; human gates D0.5, D5b)
        ↓
Phase E — Safeguards (conservative; weight-only permitted when evidence supports)
```

**Autonomous execution:** Phases A → B → C ran back-to-back on integration branch. Phase D follows [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) with human gates **D0.5** (`governance_approval_required`) and **D5b** (`model_selection_approval_required`).

**Canonical product behaviour:** [care-intelligence.md](../features/care-intelligence.md)

**Deferred roadmap** (vision only — see appendix): Care Plans, Agatha Tips, Seasonal Care, Timeline → Care Story evolution, learned ranking / ML, freemium presentation policy implementation.

---

## 4. Phase A — Care Foundation

### Goal

Create the stable domain language and Pet Profile hierarchy that all later intelligence sits on. **No recommendation generation in this phase.**

At completion, AgathaTrack should already feel calmer and clearer — without any “Agatha” suggestions.

### Prerequisites (Pet Care / Shelter separation)

Complete or verify on `main` before starting Phase A UI integration:

- Pet Care primary nav: Dashboard, Pets, Care (Actions), Account — no Fostering tab
- Dashboard: My Pets, Care Actions, Care team — no Fostering section
- Pet Detail: no Foster/Shelter sections on active Pet Care surfaces
- Pet Care client does not send foster/org linkage on new writes (D-MVP-6)
- Remove Shelter-era colour semantics from Pet Care urgency (e.g. teal “upcoming” on pet tiles)

Legacy foster/org fields may remain on persisted records and in frozen code paths; they must not define Pet Care architecture or alter Care Status.

### Deliverables

#### Domain

| Item | Notes |
|------|-------|
| `PetSpecies` normalisation | `cat`, `dog` for CIM; transitional `resolveSupportedSpecies(String raw)` acceptable |
| `CareFamily` enum | Semantic care taxonomy — see §8 migration |
| `CareSource` enum | Provenance: guardian, vet, care plan, agatha accepted/adjusted, etc. |
| `CareStatus` enum | `allSet`, `worthACheck`, `timeToFollowUp` — three states only |
| `CareStatusSummary` | Pure domain result with contributing entry IDs |
| `CareStatusService` | Deterministic; no fuzzy, no LLM, no external calls |

#### Mapping from current behaviour

```text
clear       → All Set
upcoming    → Worth a Check
dueToday    → Worth a Check
overdue     → Time to Follow Up
```

Exact “Worth a Check” review-window timing can be refined after usability validation.

#### UI

| Surface | Change |
|---------|--------|
| Pet tile status line | New three-state vocabulary and colours (see §7) |
| Pet Profile | Care Status component above profile section navigation |
| Pet Profile hierarchy | Identity → status/prompts → nav → established care preview |
| Profile prompts | Replace heavy `NeuterReminderCard` / `ChipReminderCard` with compact `ProfilePrompt` rows |
| Care event icons | CareFamily-specific icons (not generic paw for everything) |
| Design docs | Update `docs/design/system.md`, `docs/design/tokens.md`, Pet Care design docs |

#### Explicitly out of scope for Phase A

- Care Rhythms screen (Phase B)
- Agatha Suggestions (Phase C)
- `CareRecommendation` persistence
- Fuzzy inference
- Safeguards
- Care Plans
- Server-side Care Status API (may follow in Phase C if shared-care needs it; semantics must match client service)

### Completion criteria (then proceed to Phase B)

| Criterion | Required |
|-----------|----------|
| `CareStatusService` unit tests | Green — positive and negative routes |
| Pet tile + profile status | Renders all three states; accessible without colour alone |
| CareFamily icon mapping | Tested; safe fallback for `other` |
| CareFamily backfill | Strategy executed or documented default for unmigrated rows |
| Shelter teal / danger on pet-summary overdue | Removed from Pet Care surfaces |
| Design docs | Updated for Phase A deliverables |

Usability validation for status labels and colour intensity (§7) may run in parallel; do not block Phase B on it.

---

## 5. Phase B — Care Rhythms

### Goal

Expose recurring established care as a first-class Pet Care concept **without** a second recurrence engine. Care Rhythms are **care organisation**, not intelligence.

At completion, guardians have a clear place where recurring care lives — before Agatha suggests adding any.

### Deliverables

| Item | Notes |
|------|-------|
| Route | `/pet/:id/care-rhythms` (or equivalent under existing router conventions) |
| Screen | Lists recurring `HealthEntry` rows with CareFamily icon, cadence, next due, provenance |
| Profile nav | Add **Care Rhythms** row to `PetProfileSectionNav` |
| Edit / pause | Reuse existing recurrence edit flows; preserve unrelated HealthEntry fields |
| Manual add | Guardian can create a rhythm without Agatha |
| Empty state | Calm copy when no rhythms configured |

**Rule:** `Care Rhythm` = domain/presentation concept on existing recurring `HealthEntry` (`frequency != once`), refined by CareFamily where useful. Do not create a parallel scheduling data model.

### Actions vs Care Rhythms (required UX semantics)

This distinction must be obvious in copy and IA. Add to l10n and design docs.

| Surface | Question it answers | Example |
|---------|---------------------|---------|
| **Care Rhythms** | How is recurring care organised? | Flea treatment · every 12 weeks |
| **Actions** (`/pc/events`) | What needs doing now? | Flea treatment · due 21 October · overdue |

Relationship:

```text
Care Rhythm (configuration)
        ↓ generates
Action / occurrence (operational due item)
```

- The same care item may appear in both places for **different reasons**
- Actions does **not** contain unaccepted suggestions, tips, or passive observations
- Care Rhythms does **not** replace Actions; it explains *why* something appears in Actions

Suggested section subtitles:

- Care Rhythms: *“Your recurring care routines.”*
- Actions: *“What’s due from those routines and other scheduled care.”*

### Completion criteria (then proceed to Phase C)

| Criterion | Required |
|-----------|----------|
| Rhythm ↔ Actions integration | Edit cadence updates Actions schedule; completion advances next due |
| Notification consistency | Unchanged or verified against recurrence changes |
| Navigation | Profile → Care Rhythms → correct pet; responsive mobile/tablet/web |
| Negative routes | Cross-pet ID rejected; dosage fields untouched on cadence edit |

---

## 6. Phase C — Suggested by Agatha

### Goal

Build useful, **quiet** Care Intelligence without fuzzy logic, safeguards, or LLM.

Start deliberately small — **three recommendation families only:**

1. Weight monitoring rhythm suggestion
2. Dental review rhythm suggestion
3. Routine wellness review rhythm suggestion

Parasite/vaccination families: only if existing structured data makes them safe and deterministic. Do not infer from free text.

### Architecture (Phase C)

Server/backend (authoritative):

- Care Intelligence context builder
- Crisp candidate rules + curated knowledge
- `CareRecommendation` persistence and response history
- Version fields (`engineVersion`, `knowledgeVersion`, …)
- Recommendation API

Flutter:

- Fetch, render, user actions (accept / adjust / dismiss / not relevant)
- `CareSuggestionCard`, `SuggestionWhySheet`, `CareRhythmAdjustSheet`
- `PetCarePresentationPolicy` — centralised suppression (max 1 dashboard item; max 2 prominent profile surfaces)
- In-app only — no push/email for suggestions in first release

### Core rules (unchanged from v0.1)

```text
Agatha suggestion
        ↓
Guardian accepts / adjusts
        ↓
Becomes established care (HealthEntry + CareFamily + CareSource)
        ↓
Deterministic Care Status may track it
```

A suggestion alone **cannot** change Care Status.

CIM cannot override explicit veterinary cadence. `NOT_RELEVANT` suppresses resurfacing unless context changes materially.

### Completion criteria

| Criterion | Required |
|-----------|----------|
| Candidate-rule negative tests | Engine does not diagnose, auto-create care, or override vet cadence |
| Acceptance flow | Accept/adjust creates exactly one rhythm; idempotent; transactional where practical |
| Suppression policy | Existing rhythm, dismissed, not relevant — all tested |
| Analytics events | Quality events captured (presented, accepted, dismissed, not relevant) — deferred debt acceptable |

Phase C is **complete** on integration branch (PR #1085). Residual debt classified in [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) §4. Proceed to Phase D per execute-plan after replan re-approval.

---

## 7. Care Status — product-default, pending usability validation

### Semantic model (architecture locked)

Three pet-level states only:

| State | Meaning |
|-------|---------|
| **All Set** | No tracked care item requires action; no overdue items |
| **Worth a Check** | Something approaching or in a review window — not a health diagnosis |
| **Time to Follow Up** | Overdue or unresolved committed care |

Care Plan in progress is **not** a Care Status (deferred to roadmap).

### Copy and visual intensity (testable defaults)

The following are **product-defaults pending usability validation**, not permanently locked:

- Exact English labels (“Worth a Check”, “Time to Follow Up”)
- Plum accent for Time to Follow Up at pet-summary level (vs red in Actions list)
- Info blue for Worth a Check
- Prominence and density of the status component on Pet Profile

### Validation protocol (before calling copy/colours locked)

Test ~5–6 guardians with scenario cards:

> “You see this on Buddy’s profile. What do you think it means? What would you do?”

**Fail signals:**

- “Worth a Check” interpreted as “my pet might be ill”
- “Time to Follow Up” not understood as overdue scheduled care
- Status colour alone carries meaning without reading text

Adjust copy and colour intensity based on results. Architecture (three states, separation from suggestions) remains fixed.

### Visual defaults (implementation starting point)

| State | Accent | Notes |
|-------|--------|-------|
| All Set | `success` | Sparse green |
| Worth a Check | `info` | No amber warning |
| Time to Follow Up | Pet Care `primary` | No orange/red at pet-summary level |
| Agatha suggestion | `accent` / `lightAccent` | Distinct from plum |

Reserve warning/danger tokens for genuine error semantics and **within Actions** operational overdue styling where appropriate.

---

## 8. CareFamily — migration and backfill

`CareFamily` is not a trivial enum add. It affects iconography, grouping, CIM rules, duplicate suppression, knowledge lookup, and future analytics.

### Enum (initial)

```dart
enum CareFamily {
  medication,
  vaccination,
  parasitePrevention,
  wellnessReview,
  dental,
  weightMonitoring,
  grooming,
  nailCare,
  other,
}
```

`HealthEntryType` (medication / preventive / vetVisit / other) is **not** replaced. They answer different questions:

- `HealthEntryType` → operational event type
- `CareFamily` → semantic care domain

### Backfill strategy (required before CIM rules depend on family)

For existing `HealthEntry` rows, apply **conservative** deterministic mapping:

| Signal | Map to |
|--------|--------|
| `type == medication` | `medication` |
| `type == vetVisit` | `wellnessReview` (or `other` if notes clearly indicate non-wellness) |
| `type == preventive` | **Do not** auto-split to parasite vs vaccination unless existing metadata reliably distinguishes |
| Ambiguous / insufficient metadata | `other` |

**Never pretend the migration knows more than the data supports.**

Document default for new field on unmigrated rows: `other` or null-with-safe-fallback in UI.

### Phase A requirements

- Migration plan written and reviewed
- Round-trip persistence for `CareSource` and `CareFamily`
- Tests: each family maps to intended icon; unknown → safe generic
- Tests: family does not alter recurrence behaviour

---

## 9. Species scope and graceful handling

### CIM v1 species scope

Agatha Suggestions: **cats and dogs only** (structured `PetSpecies`).

Architecture remains extensible; content/rules are not generalised to rabbits, birds, etc. in early phases.

### What works for all species

| Capability | All supported species |
|------------|----------------------|
| Care Status | Yes — tracks explicit guardian-configured care |
| Manual Care Rhythms | Yes |
| Actions / due items | Yes |

### Agatha Suggestions

- Appear **only** for cats and dogs
- Do **not** show “AI not available for rabbits” on every screen
- If user reaches Suggested Care settings or learn-more:  
  *“Personalised care suggestions are currently available for cats and dogs. More species will follow.”*

Unsupported species must not crash Care Status or rhythm flows.

---

## 10. Phase D — Review Relevance

**Status:** active (not started — awaiting execute-plan re-approval after replan PR)

| Reference | Document |
|-----------|----------|
| Canonical product behaviour | [care-intelligence.md](../features/care-intelligence.md) |
| Execution plan (D0–D7) | [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) |

**Scope:** weight-first, internal-only until Phase E. No production safeguard UI.

**Human gates:** D0.5 (`governance_approval_required`) before research on production user data; D5b (`model_selection_approval_required`) before Phase E scope lock.

**Explicitly not in Phase D:** guardian-facing safeguards, fuzzy outputs, LLM integration, multi-signal production logic.

Detailed mechanics, ownership, benchmark staging, and completion criteria live in the execution plan — not duplicated here.

---

## 11. Phase E — Safeguards

### Hard requirements

> **Multi-signal safeguards** (e.g. weight + activity) require at least two reliable structured longitudinal signal families with validated capture behaviour.

> **Weight-only safeguards** are permitted when evidence supports — see [care-intelligence.md](../features/care-intelligence.md) (single-signal copy rule, high bar, structured context in production).

The Luna mockup (weight decline + lower activity) remains in the **vision appendix** until a second signal is validated.

Proceed to Phase E only after **D5b** approval on the Phase D plan.

### Minimum bar for any production safeguard

Even weight-only:

- Sufficient measurement count and spacing
- Unit consistency
- Personal baseline confidence thresholds
- Robust outlier handling
- False-positive/false-negative evaluation documented in implementation notes

### Safeguard UX (when criteria met)

- Info blue calm card — “Worth checking with your vet”
- No diagnosis, disease names, alarm animation, or emergency classification
- Actions: View changes, Dismiss
- `CimEvidenceView` shows facts only
- In-app only initially

Weight-only pattern detection may be prototyped internally before Phase E ship criteria are met.

---

## 12. Stable architecture reference

These boundaries apply across all phases.

### Message hierarchy (collision / suppression)

Priority (highest first):

1. Safeguard (Phase E+)
2. Time to Follow Up (Care Status)
3. Worth a Check (Care Status)
4. Active Care Plan (roadmap)
5. Suggested Care (Phase C+)
6. Seasonal Care (roadmap)
7. Agatha Tip (roadmap)

Pet Profile: max **2** prominent contextual surfaces. Dashboard: normally max **1** CIM contextual item. Render nothing when there is nothing meaningful to show.

### Source precedence (strongest first)

1. Explicit veterinary instruction
2. Explicit treatment/product schedule
3. Guardian-defined care
4. Active Care Plan
5. Individual pet context
6. Approved species/life-stage guidance
7. Generic AgathaTrack default

### Presentation policy

Do not scatter card-selection logic across widgets. Use a central `PetCarePresentationPolicy` / `PetCareOverview` composed view model.

### Server vs client

Phase A–B: Care Status may remain client-derived if semantics are centralised in one `CareStatusService`.

Phase C+: recommendation generation and persistence are server-authoritative.

### Notifications

| Type | Phase C+ behaviour |
|------|-------------------|
| Established tracked care | Existing notification behaviour |
| Suggested Care | In-app only |
| Safeguards | In-app only until explicitly designed |

### Freemium (principle only — implementation deferred)

Generate intelligence first; presentation/subscription policy is separate. Safety-relevant core warnings must not be paywalled. Decide specific family boundaries before Plus gating ships.

### Feature boundary (Flutter)

```text
flutter_app/lib/features/care_intelligence/   # Phase C+ suggestions, safeguards
```

`CareStatus` belongs in broader Pet Care / care foundation, not inside `care_intelligence`.

`CareRhythm` is established care — not inside `care_intelligence`.

### Negative tests (first-class across all phases)

Examples that must exist somewhere in the test suite:

- Suggestion does not alter Care Status before acceptance
- CIM cannot override explicit veterinary cadence
- `NOT_RELEVANT` does not resurface without material context change
- Accept cannot duplicate recurring care
- Unsupported species does not receive cat/dog CIM recommendations
- Missing/poor longitudinal data does not trigger high-confidence safeguard
- Safeguard copy contains no diagnosis or medication advice
- Suggestions never appear in Actions before acceptance
- Missing chip/neuter does not appear as alarmist medical recommendation

---

## 13. Definition of done (per phase)

Each phase is complete only when:

1. Domain behaviour implemented
2. UI matches design system defaults (or documented deviations from usability test)
3. Localisation strings added
4. Unit tests pass — including negative routes
5. Widget/integration tests pass where relevant
6. Responsive states verified
7. Canonical docs updated in the same phase
8. No new Shelter/Fostering coupling introduced
9. Lint/static analysis passes

Phases A → B → C: complete on integration branch.

Phase D: per [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md); human gates D0.5 and D5b.

Phase E: after D5b approval; per [care-intelligence.md](../features/care-intelligence.md).

---

## 14. Vision appendix (not active implementation)

The following remain valid **product direction** but are **out of scope** for Phases A–E unless explicitly promoted in a future spec revision.

### Care Plans

Structured care journeys (recovery, weight management, medication monitoring). Separate dimension from Care Status. Shown in mockups; implement after foundation and rhythms are stable.

### Agatha Tips

Curated informational content. No status impact, no obligation, ~1 per 1–2 weeks max. Not Phase C.

### Seasonal Care

Optional contextual checklist. Does not create overdue status unless accepted into tracked care.

### Timeline → Care Story

Evolve existing Timeline toward clinical + care + life history. Requires Foster/Custody timeline cleanup first.

### Learned ranking / ML

Deferred until structured feedback volume exists. Target: usefulness model, not “medical correctness from acceptance.”

### Multi-signal safeguard (Luna example)

> Worth checking with your vet — weight gradually decreased and lower activity recorded.

Vision-only until activity (or equivalent second signal) is a validated, structured longitudinal data source. **Weight-only** safeguards may ship earlier per feature doc when D5b approves.

### Locked UX decisions from v0.1 that remain architecture-locked

- Care Status has exactly three states
- Care Plan is separate from Care Status (when built)
- Suggested Care does not affect status until accepted
- Agatha suggestion uses warm accent, not AI purple
- No CIM navigation tab
- Unaccepted suggestions never in Actions
- Sparse profiles are not nagged into completion
- No second recurrence engine

---

## 15. Cursor handoff — start here

**Execution model**

| Phases | Behaviour |
|--------|-----------|
| **A → B → C** | Complete on integration branch (`cursor/care-foundation-c7a1-integration-dc3b`). |
| **D** | [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) — resume at **D0** after replan PR merges and execute-plan **re-approval** on [#1082](https://github.com/KanopeeKa/AgathaCheck/issues/1082). |
| **E** | After D5b (`model_selection_approval_required`). |

**Canonical behaviour:** [care-intelligence.md](../features/care-intelligence.md)

Do **not** implement recommendation generation, fuzzy inference, or safeguards in Phase A–C workstreams.

---

## Appendix A — Canonical colour tokens

Use token names from [`docs/design/tokens.md`](../../../design/tokens.md) (hex values live there only). Pet Care–relevant roles:

| Role | Token |
|------|-------|
| Background | `background` |
| Surface | `surface` |
| Grouped surface | `surfaceAlt` |
| Border | `border` |
| Pet Care primary plum | `primary` (Pet Care mode) |
| Pet Care icon support | `plum-400` (see [`system.md`](../../../design/system.md)) |
| Pet Care soft icon surface | `light` |
| Warm Agatha accent | `accent` |
| Warm Agatha surface | `lightAccent` |
| Information | `info` |
| Success | `success` |
| Warning | `warning` |
| Danger | `danger` |

Warning/danger are not ordinary Care Status colours at pet-summary level.

---

## Appendix B — Useful codebase paths

```text
flutter_app/lib/features/pet_profile/domain/entities/pet.dart
flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart
flutter_app/lib/features/pet_profile/presentation/screens/pet_detail_screen.dart
flutter_app/lib/features/pet_profile/presentation/widgets/pet_tile_status_line.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_helpers.dart
flutter_app/lib/features/experience/presentation/config/pet_care_primary_destinations.dart
flutter_app/lib/core/theme/app_color_tokens.dart
docs/design/system.md
docs/design/tokens.md
docs/engineering/frozen-domains/mvp-pivot-decisions.md
```

---

## Appendix C — Synthetic evaluation fixtures

Operational fixture detail lives in [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md) Appendix A. Summary personas:

| Fixture | Expected |
|---------|----------|
| Cat A — young, sparse profile | All Set; no noisy suggestion |
| Cat B — adult, stable history | Contextual suggestions possible; no safeguard |
| Cat C — senior, weight decline | Internal relevance only; no production safeguard without gates |
| Cat D — decline + second reliable signal | Gentle safeguard **only after Phase E gates** |
| Cat E — vet appointment tomorrow | Suppress or soften “bring appointment forward” |
| Cat F — sparse/unreliable measurements | No strong safeguard |
| Dog B — vet-directed weight monitoring | Vet cadence always wins |
| Dog C — grooming marked Not Relevant | No repeated grooming suggestion |

---

---

## 16. Successor programme — Care Progression

Phases A–E (this roadmap) complete the **Care Foundation & Intelligence** programme. The **next** Pet Care programme is **Care Progression** — a separate execute-plan, not an extension of `care-foundation-c7a1`.

**Starts when:** Phase E (guardian safeguards) is merged to `main`.

| Document | Role |
|----------|------|
| [care-progression.md](../features/care-progression.md) | Canonical product semantics |
| [care-progression-delivery-plan.md](./care-progression-delivery-plan.md) | CP-0–CP-7 implementation sequencing |

Care Progression covers Established maturity, Milestones, and weight occurrence ↔ observation evidence. It does **not** extend Phase D/E scope or modify the CIM execute-plan snapshot.

---

*End of Care Foundation & Intelligence Roadmap v0.4*
