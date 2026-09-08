---
title: D0 — Weight provenance contract
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-08
tags: [pet_care, care_intelligence, phase_d, d0]
---

# D0 — Weight provenance contract

**Canonical behaviour:** [care-intelligence.md](../features/care-intelligence.md)  
**Delivery plan:** [phase-d-review-relevance-plan.md](./phase-d-review-relevance-plan.md)

D0 freezes three **non-inferable** provenance concepts. `health_entries.care_source` remains rhythm provenance only.

---

## 1. Concepts

| Concept | Scope | Storage (v1) |
|---------|-------|----------------|
| `measurementSource` | Per weight entry | `weight_entries.measurement_source` |
| `referenceAuthority` | Pet weight reference | `pets.weight_reference_authority` + `pets.weight_reference_value` |
| `managementContext` | Active weight management | `pets.weight_management_context` |

**Rule:** Never infer one from another.

---

## 2. Wire enums

### measurement_source (weight entry)

| Value | Meaning |
|-------|---------|
| `guardian` | Default — guardian-entered |
| `clinic` | Veterinary clinic |
| `device` | Connected device |
| `imported` | External import |

### weight_reference_authority (pet)

| Value | Meaning |
|-------|---------|
| `vet_target` | Vet-provided target |
| `guardian_reference` | Guardian healthy-reference estimate |
| `historical_baseline` | Derived from pet history |

### weight_management_context (pet)

| Value | Meaning |
|-------|---------|
| `none` | Default |
| `vet_managed` | Under active vet management |
| `care_plan` | Structured care plan |
| `treatment_related` | Treatment schedule |

---

## 3. API surfaces (D0)

### Weight entries

- **GET** responses include `measurement_source` (default `guardian` for legacy rows).
- **POST/PUT** accept optional `measurement_source` / `measurementSource`; invalid values → 400.

### Pets

- **GET** includes `weight_reference_value`, `weight_reference_authority`, `weight_management_context`.
- **PUT** accepts optional weight context fields independently (partial update supported).

---

## 4. Code artifacts

| Artifact | Path |
|----------|------|
| Server validators | `server/routes/careIntelligence/provenance.js` |
| WeightChangeSpec sketch | `server/routes/careIntelligence/weightChangeSpec.js` |
| Evidence trace factory | `server/routes/careIntelligence/evidenceTrace.js` |
| D6 benchmark JSON schema | `server/routes/careIntelligence/benchmark/caseSchema.json` |
| Flutter enums | `flutter_app/lib/features/care_intelligence/domain/weight_provenance.dart` |
| Migration | `db/migrations/055_weight_provenance_contract.sql` |

---

## 5. D6.0 benchmark case fields

Per-reviewer (never erased by adjudication):

- `reviewerDecision`, `reviewerConfidence`, `reviewerRationale`

Case-level:

- `reviewers[]`, `adjudicatedLabel`, `adjudicationReason`, `disagreementFlag`

Disputed cases use `uncertain/reviewer_disagreement` — adjudicated label is one view, not training truth.

---

## 6. D0.5 gate

Before research using production user data:

- Product/governance sign-off on this contract
- Execute-plan halt: `governance_approval_required`

Progressive capture UI ships in D3 parallel micro-PRs; D0 establishes persistence and wire contract only.

---

## 7. Regulatory touchpoints

| Data | Classification | Notes |
|------|----------------|-------|
| `measurement_source` | Pet health metadata | Low sensitivity; audit on weight entry writes |
| Weight reference/context | Pet health metadata | Used for suppression only in Phase D |
| `PhaseDEvidenceTrace` | Internal research | Ephemeral by default; map before persistence in DATA_MAP |

Update [DATA_MAP.md](/regulatory/DATA_MAP.md) when traces persist beyond ephemeral evaluation.
