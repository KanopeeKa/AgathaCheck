---
title: Care Intelligence
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_intelligence
status: active
related_prs: []
related_bdd: []
---

# Care Intelligence

**Internal working name:** CIM — Care Intelligence Model  
**User-facing name:** Agatha / “Suggested by Agatha”

Care Intelligence helps guardians **understand** longitudinal pet-care data and occasionally surfaces **review-relevant** observations. It is not a symptom checker, diagnostic engine, or autonomous care planner.

**Related domains:** weight and health data live under [health_tracking](/docs/domains/health_tracking/README.md). Care rhythm provenance uses `CareSource` on recurring `health_entries` — see [Care Foundation roadmap](../changes/care-foundation-roadmap.md) Phases A–C.

---

## Purpose

| In scope | Out of scope |
|----------|--------------|
| Quiet rhythm suggestions (Phase C) | Diagnosis, disease naming, emergency classification |
| Internal review-relevance evaluation (Phase D) | LLM clinical reasoning in production |
| Conservative guardian safeguards when evidence supports (Phase E) | Symptom checker or “AI vet” UX |
| Explainable evidence traces for engineering and clinical review | Confidence percentages shown to guardians |
| Suppression when context explains the change | Overriding explicit veterinary cadence |

---

## Non-goals

- AgathaTrack must **not** feel like an AI application.
- Care Intelligence must **not** infer one provenance concept from another (see Provenance model).
- Unaccepted suggestions must **never** appear in Actions or change Care Status.
- Production safeguards must **not** use plural “patterns/signals” copy unless genuinely independent signal families contributed.

---

## Review relevance

**Review relevance** means: given available structured data and guardian/vet context, is there a **material, persistent change** that a reasonable guardian might want to **mention to their vet**, after ordinary explanations are ruled out?

Review relevance is **not**:

- a diagnosis;
- an emergency triage decision;
- a substitute for scheduled care overdue status (Care Status handles committed rhythms).

---

## Authority hierarchy

When signals conflict, higher authority wins for **suppression** and **explanation**:

1. Explicit **vet instruction** or documented treatment schedule
2. Active **care plan** or accepted Agatha rhythm the guardian is following
3. Guardian-declared **reference** or management context
4. Statistical / trend inference from measurements

CIM cannot override explicit veterinary cadence. `NOT_RELEVANT` and dismiss suppress resurfacing unless context changes materially.

---

## Change semantics

| Term | Meaning |
|------|---------|
| **Ordinary change** | Expected variation (life stage, single measurement noise, known plan in progress) |
| **Explained change** | Trend or deviation accounted for by recorded context (target weight plan, vet-managed treatment, etc.) |
| **Unexplained change** | Material, persistent deviation with no adequate recorded explanation |

Only **unexplained** material changes are candidates for internal review-relevance flags or Phase E safeguards.

---

## Silence principle

**Default is silence.** Absence of a suggestion or safeguard is often correct.

Do not surface when:

- data quality is inadequate;
- sample size or spacing is insufficient;
- life-stage norms explain the pattern;
- intentional weight/management context is recorded;
- an existing rhythm or prior dismissal applies;
- species is outside supported suggestion scope (cats and dogs for Phase C suggestions).

---

## Suggestions vs safeguards

| Surface | Phase | Guardian-visible | Changes Care Status |
|---------|-------|------------------|-------------------|
| **Suggested by Agatha** (rhythm proposals) | C (shipped) | Yes | No — until accept/adjust |
| **Review-relevance evaluation** | D (internal) | No | No |
| **Safeguards** (“worth mentioning to your vet”) | E | Yes, when gated | No |

A suggestion alone **cannot** change Care Status. Safeguards are **informational**, not alarms.

---

## Provenance model (frozen concepts)

Three concepts are **distinct**. Agents must not overload `CareSource` (rhythm provenance on `health_entries`) to represent all three.

### 1. `measurementSource`

Who or what produced **this measurement**?

| Value | Meaning |
|-------|---------|
| `guardian` | Guardian-entered |
| `clinic` | Veterinary clinic |
| `device` | Connected scale or device |
| `imported` | Imported from external record |

### 2. `referenceAuthority`

What is the **reference or target** being compared against, and who established it?

| Value | Meaning |
|-------|---------|
| `vet_target` | Vet-provided target |
| `guardian_reference` | Guardian’s healthy-reference estimate |
| `historical_baseline` | Derived from pet’s own history |

Persist **provenance**, not only the numeric reference (e.g. `referenceValue` + `referenceSource`, not a bare `targetWeight`).

### 3. `managementContext`

Is an **intentional management plan** already active for this concern?

| Value | Meaning |
|-------|---------|
| `none` | No recorded active management |
| `vet_managed` | Under active vet management |
| `care_plan` | Part of a structured care plan |
| `treatment_related` | Linked to treatment schedule |

**Rule:** Never infer `referenceAuthority` from `measurementSource`, or `managementContext` from either. Capture each at the moment it becomes relevant (progressive contextual capture).

---

## Data-quality gating

Before review-relevance or safeguard logic runs:

- sufficient measurement **count** and **spacing**;
- **unit** consistency;
- outlier handling documented;
- personal baseline confidence thresholds met.

Poor or sparse longitudinal data must not produce high-confidence guardian messaging.

---

## Evidence and explainability

Internal evaluation and future guardian safeguards must be **traceable**:

- which measurements contributed;
- which rules or classifiers fired;
- which suppression context applied;
- engine/knowledge version identifiers.

Future persistence types (design-approved, not necessarily shipped): `CareSignalEvidence`, `CareSafeguard`, ephemeral `PhaseDEvidenceTrace` for research runs.

---

## Single-signal guardian copy

When only **one evidence family** (e.g. weight) supports a safeguard:

- Copy must **name that family** explicitly.
- Do **not** use plural language (“several health patterns”, “multiple signals”) unless independent signal families genuinely contributed.

Example (acceptable):

> “Luna’s weight has been trending down across several measurements. There isn’t a known weight plan recorded, so it may be worth mentioning this to your vet.”

Example (not acceptable):

> “Agatha detected a concerning health pattern.”

---

## Weight-only safeguards (Phase E)

A **weight-only** safeguard is permitted without a second longitudinal signal family, subject to a **high bar**:

- measurement quality adequate;
- change material for this pet;
- change persistent / supported by history;
- life-stage explanation does not account for it;
- no known intentional weight plan explains it;
- no vet instruction already covers it;
- **structured context** required for the safeguard class exists in production (reference provenance, management context).

Multi-signal safeguards (e.g. weight **and** activity) remain vision-only until a second signal family is validated — see roadmap vision appendix.

---

## Species scope

- **Suggestions (Phase C):** cats and dogs only; unsupported species must not crash Care Status or rhythms.
- **Safeguards:** follow Phase D/E evaluation scope; do not generalise from cat/dog benchmarks without explicit approval.

---

## Regulatory and privacy

Benchmark curation, evidence traces, and any production safeguard persistence must align with [DATA_MAP.md](/regulatory/DATA_MAP.md) and [INTERNAL_GDPR.md](/regulatory/INTERNAL_GDPR.md). Phase D internal evaluation defaults to **no production user data** until human gates approve otherwise.

---

## Delivery status (pointer only)

| Artifact | Role |
|----------|------|
| [Care Foundation roadmap](../changes/care-foundation-roadmap.md) | Programme sequencing (Phases A–E) |
| [Phase D Review Relevance plan](../changes/phase-d-review-relevance-plan.md) | Phase D research/delivery mechanics (D0–D7) |
| Execute-plan `care-foundation-c7a1` | Autonomous implementation state — control issue [#1082](https://github.com/KanopeeKa/AgathaCheck/issues/1082) |
| [Care Progression](../features/care-progression.md) | **Next programme** (after Phase E) — not part of CIM |

Phase mechanics, gates, and completion criteria belong in the delivery plan, not in this document.
