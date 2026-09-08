---
title: Phase D — Review Relevance Plan
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, phase_d, delivery]
---

# Phase D — Review Relevance Plan

**Canonical product behaviour:** [care-intelligence.md](../features/care-intelligence.md)  
**Programme roadmap:** [care-foundation-roadmap.md](./care-foundation-roadmap.md) v0.4  
**Execute-plan:** `care-foundation-c7a1` — control issue [#1082](https://github.com/KanopeeKa/AgathaCheck/issues/1082)  
**Integration branch:** `cursor/care-foundation-c7a1-integration-dc3b`

**Scope:** weight-first, **internal-only** until Phase E. No production guardian safeguard UI in Phase D.

---

## 0. How to use this document

| Kind | Location |
|------|----------|
| Durable product rules | `../features/care-intelligence.md` |
| Programme sequencing | `./care-foundation-roadmap.md` |
| This file | Time-bound D0–D7 mechanics — **archive or delete** after Phase D; extract durable conclusions into the feature doc first |

---

## 1. Goal

Determine whether longitudinal **weight** changes are **review-relevant** (worth mentioning to a vet) under AgathaTrack’s authority hierarchy and silence principle — using in-repo deterministic engineering artifacts and a staged expert benchmark.

**Not in Phase D:** production safeguard UI, fuzzy outputs to guardians, LLM integration, multi-signal production safeguards.

---

## 2. Ownership

### Engineering (in-repo deterministic / runtime)

- Weight feature extraction module
- D1 measurement-quality classifier
- `WeightChangeSpec` implementation
- Reference-vector and suppression tests
- Evaluation harness and evidence-trace types
- Structured context prerequisites (API + persistence)
- Regulatory mapping updates when traces touch persisted data

### Research / product

- Benchmark curation (D6)
- Label rubric and hindsight rules
- External lawful-source evaluation
- D5a comparative analysis
- D6 expert-review process
- D5b recommendation document

### Clinical reviewer (advise / adjudicate)

- Review-relevance rubric
- Ambiguous case adjudication
- Clinical reasonableness sign-off at D5b

---

## 3. Provenance model (D0 deliverable)

Freeze three **separate** concepts in D0. Do **not** overload `CareSource` on `health_entries`.

| Concept | Scope | Example values |
|---------|-------|----------------|
| `measurementSource` | Per weight measurement | `guardian`, `clinic`, `device`, `imported` |
| `referenceAuthority` | Pet/reference context | `vet_target`, `guardian_reference`, `historical_baseline` |
| `managementContext` | Active management for concern | `none`, `vet_managed`, `care_plan`, `treatment_related` |

**Rules:**

- Never infer one from another.
- `CareSource` remains rhythm provenance on recurring care entries only.
- Progressive capture at moment of relevance — no standalone clinical configuration screen.

**D0 exit:** written contract (types, wire format, UI touchpoints, migration if needed) approved at D0.5 gate.

---

## 4. Phase C residuals

| Item | Classification | Notes |
|------|----------------|-------|
| Provenance model (`measurementSource`, `referenceAuthority`, `managementContext`) | **BLOCKER to D1** | D0 deliverable |
| Guardian reference weight capture | **PARALLEL micro-PR** | Ready before D3 needs prod semantics |
| Vet / active-management context capture | **PARALLEL micro-PR** | Same |
| `CareRhythmAdjustSheet` | **Phase C debt** | Polish; not D0 blocker |
| Care intelligence context builder | **Phase C debt** | Unless D3 blocked — evaluate in D0 |
| Suggestion analytics events | **Phase C debt** | Quality events; not D1 blocker |

---

## 5. Phases and gates

```text
D0  Semantics & data contracts
      ↓
D0.5  HUMAN GATE — governance_approval_required
      ↓
D1  Weight quality classifier + feature extraction
D2  WeightChangeSpec + reference vectors
      ↓ (parallel: context micro-PRs)
D3  Suppression / structured context integration
D4a Design-only — second signal family (no implementation)
D5a Internal evaluation vs reference vectors
      ↓
D6  Staged benchmark (D6.0 → D6.1 → D6.2)
      ↓
D5b HUMAN GATE — model_selection_approval_required
      ↓
D7  Phase E handoff contract
```

### Execute-plan halt mapping

| Gate | When | `status` | `status_reason` | Resume |
|------|------|----------|-----------------|--------|
| **D0.5** | Contracts + rubric draft ready; before research on prod user data | `halted` | `governance_approval_required` | Product owner comments `resume-plan` on #1082 after sign-off |
| **D5b** | D5a + D6 complete; before Phase E scope lock | `halted` | `model_selection_approval_required` | Clinical/product sign-off on #1082 |

These reasons are machine-readable in the execute-plan schema — distinct from generic `human_pause`.

### Re-approval (post replan)

The autonomous grant for **Phases A–C only** (2026-09-07) is **superseded**. Phase D execution requires a **new approval window** on #1082 (`approve-autonomous care-foundation-c7a1` with refreshed `approved_at` / `approved_until`) after this replan PR merges. Do not resume D0 until re-approved.

---

## 6. D0 — Semantics & data contracts

**Deliverables:**

- Provenance model contract (§3)
- Review-relevance definition aligned with [care-intelligence.md](../features/care-intelligence.md)
- `WeightChangeSpec` interface sketch
- Trace type sketch (`PhaseDEvidenceTrace` — ephemeral research default)
- Regulatory touchpoint list (DATA_MAP deltas)
- D6.0 benchmark schema draft (case fields, reviewer boundary, hindsight rules)

**Exit:** ready for D0.5 gate.

---

## 7. D1 — Weight quality classifier

**Deliverables:**

- In-repo classifier: adequate vs inadequate measurement series
- Unit tests with reference vectors
- Documented thresholds (count, spacing, outliers)

**Depends on:** D0.5 approval; provenance contract (blocker).

---

## 8. D2 — WeightChangeSpec & reference vectors

**Deliverables:**

- `WeightChangeSpec` implementation (materiality, direction, persistence)
- Life-stage and species-aware ordinary-change rules
- Reference-vector test suite (golden cases)

---

## 9. D3 — Suppression & structured context

**Deliverables:**

- Wire `referenceAuthority` and `managementContext` into suppression pipeline
- Progressive capture UI (micro-PRs may land in parallel with D1/D2)
- Tests: explained change suppresses; vet_target suppresses false alerts

**Phase E prerequisite:** structured context needed for the safeguard class must exist in **production** before Phase E ships — not a backlog-only item.

---

## 10. D4a — Second signal design only

Document appetite, activity, or BCS as a **future** signal family. No implementation, no production dependency.

---

## 11. D5a — Internal evaluation

**Deliverables:**

- Run harness on reference vectors + synthetic fixtures
- Safety regression suite (no diagnosis in traces, silence on sparse data)
- Written analysis: crisp sufficiency vs fuzzy experiment warrant

**Does not require** large vet-reviewed D6 set.

---

## 12. D6 — Staged benchmark

### D6.0 — Benchmark design (with D0)

Case schema, reviewer information boundary, label provenance, hindsight rules, acceptable expert judgement definition.

### D6.1 — Small expert-curated set (~20–50 cases)

**Purpose:** validate the question, expose ambiguity, test suppression, compare approaches, learn reviewer disagreement — **not** statistical power.

Cases may combine lawful external trajectories with constructed context; provenance must be explicit.

### D6.2 — Grow benchmark

Only after rubric works: larger vet-reviewed set or ethically governed AgathaTrack cases.

### Reviewer disagreement (first-class)

Do **not** force consensus. Do **not** let adjudication erase disagreement.

Per reviewer:

```text
reviewerDecision
reviewerConfidence
reviewerRationale
```

Case-level:

```text
reviewers[]
adjudicatedLabel
adjudicationReason
disagreementFlag
```

Disputed cases → `uncertain/reviewer_disagreement` in benchmark taxonomy; adjudicated label is **one view**, not erased training truth.

---

## 13. D5b — Model selection gate

**Deliverables:**

- Recommendation: proceed to Phase E weight-only safeguard, defer, or narrow scope
- Clinical reasonableness review
- Explicit sign-off before guardian-facing work

**Halt:** `model_selection_approval_required` until #1082 resume.

---

## 14. D7 — Phase E handoff contract

**Deliverables:**

- Minimum evidence bar for weight-only safeguard
- Copy templates obeying single-signal rule (feature doc)
- Persistence decision for `CareSafeguard` / traces
- DATA_MAP updates

---

## 15. Engineering vs notebook rule

All evaluation artifacts that inform production behaviour must live **in-repo** (harness, classifier, specs, tests). Jupyter or ad-hoc notebooks may explore; they do **not** define production thresholds without corresponding committed code and tests.

---

## 16. Completion criteria (Phase D)

| Criterion | Required |
|-----------|----------|
| D0.5 approved | Provenance contract signed off |
| D1–D2 shipped | Quality classifier + WeightChangeSpec + tests |
| D3 | Suppression integrated; context capture in prod |
| D5a | Written evaluation + safety regression green |
| D6.1 | Benchmark rubric validated; disagreement preserved |
| D5b approved | Phase E scope locked |
| D7 | Handoff doc complete |
| Feature doc updated | Durable conclusions extracted from this plan |
| Regulatory | DATA_MAP reflects any new persistence |

After completion: archive or delete this file per [documentation standards](/docs/domains/documentation/standards.md).

---

## Appendix A — Synthetic fixtures

Use in-repo reference vectors and synthetic cases for D1–D5a. Expert-curated cases (D6.1) supplement — not replace — deterministic regression tests.

## Appendix B — Weight-only Phase E preview (not Phase D scope)

Guardian copy may ship in Phase E when D5b approves, subject to feature-doc single-signal rule and production structured context. Phase D remains internal-only.
