---
title: Care Intelligence
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_intelligence
status: active
last_updated: 2026-10-08
related_prs: []
---

# Care Intelligence

**Internal working name:** CIM — Care Intelligence Model  
**User-facing name:** Agatha / “Suggested by Agatha”

Care Intelligence helps guardians **understand** longitudinal pet-care data and occasionally surfaces **review-relevant** observations. It is not a symptom checker, diagnostic engine, or autonomous care planner.

## Summary / scope

- **Owns:** Quiet rhythm suggestions (Phase C); internal review-relevance evaluation (Phase D); conservative guardian safeguards when evidence supports (Phase E); provenance axes for weight context (`measurementSource`, `referenceAuthority`, `managementContext`); explainable evidence traces; suppression and resurface policy; single-signal guardian copy rules.
- **Does not own:** Care Status or overdue semantics ([care-schedule-management.md](./care-schedule-management.md)); establishment and milestones ([care-progression.md](./care-progression.md)); occurrence commands ([care-item-evolution.md](./care-item-evolution.md)); weight storage wire rules ([weight-monitoring-model.md](../../weight_tracking/features/weight-monitoring-model.md)).
- **Depends on:** Recurring care and `CareSource` on `health_entries`; weight observations; CSM `explainGap` for schedule facts ([care-schedule-management.md](./care-schedule-management.md) CSM-13); presentation slot ordering with progression and milestones ([care-progression.md](./care-progression.md) CARE-PROGRESSION-R-024).

**Programme sequencing (pointers only):** [care-foundation-roadmap.md](../changes/care-foundation-roadmap.md) Phases A–E · Phase D mechanics [phase-d-review-relevance-plan.md](../changes/phase-d-review-relevance-plan.md) · Execute-plan `care-foundation-c7a1` control [#1082](https://github.com/KanopeeKa/AgathaCheck/issues/1082).

```text
care_planning / care_observations
        ↓
   care_intelligence  (suggestions, review relevance, safeguards)
        ↓
   care_presentation  (collision, copy shaping)
```

## Purpose

| In scope | Out of scope |
|----------|--------------|
| Quiet rhythm suggestions (Phase C) | Diagnosis, disease naming, emergency classification |
| Internal review-relevance evaluation (Phase D) | LLM clinical reasoning in production |
| Conservative guardian safeguards when evidence supports (Phase E) | Symptom checker or “AI vet” UX |
| Explainable evidence traces for engineering and clinical review | Confidence percentages shown to guardians |
| Suppression when context explains the change | Overriding explicit veterinary cadence |

AgathaTrack must **not** feel like an AI application. Unaccepted suggestions must **never** appear in Actions or change Care Status.

## Review relevance

**Review relevance** means: given available structured data and guardian/vet context, is there a **material, persistent change** that a reasonable guardian might want to **mention to their vet**, after ordinary explanations are ruled out?

Review relevance is **not** a diagnosis, an emergency triage decision, or a substitute for scheduled care overdue status (Care Status handles committed rhythms).

## Authority hierarchy

When signals conflict, higher authority wins for **suppression** and **explanation**:

1. Explicit **vet instruction** or documented treatment schedule
2. Active **care plan** or accepted Agatha rhythm the guardian is following
3. Guardian-declared **reference** or management context
4. Statistical / trend inference from measurements

CIM cannot override explicit veterinary cadence. `NOT_RELEVANT` and dismiss suppress resurfacing unless context changes materially.

## Change semantics

| Term | Meaning |
|------|---------|
| **Ordinary change** | Expected variation (life stage, single measurement noise, known plan in progress) |
| **Explained change** | Trend or deviation accounted for by recorded context (target weight plan, vet-managed treatment, etc.) |
| **Unexplained change** | Material, persistent deviation with no adequate recorded explanation |

Only **unexplained** material changes are candidates for internal review-relevance flags or Phase E safeguards.

## Silence principle

**Default is silence.** Absence of a suggestion or safeguard is often correct.

Do not surface when: data quality is inadequate; sample size or spacing is insufficient; life-stage norms explain the pattern; intentional weight/management context is recorded; an existing rhythm or prior dismissal applies; species is outside supported suggestion scope (cats and dogs for Phase C suggestions).

## Suggestions vs safeguards

| Surface | Phase | Guardian-visible | Changes Care Status |
|---------|-------|------------------|---------------------|
| **Suggested by Agatha** (rhythm proposals) | C (shipped) | Yes | No — until accept/adjust |
| **Review-relevance evaluation** | D (internal) | No | No |
| **Safeguards** (“worth mentioning to your vet”) | E | Yes, when gated | No |

A suggestion alone **cannot** change Care Status. Safeguards are **informational**, not alarms.

### Safeguard resurface policy

A dismissed weight safeguard resurfaces only when the trend **materially** worsens, not on every new measurement. Magnitude is bucketed into 5% bands; a dismissed safeguard reactivates only when the trend crosses **two** bucket boundaries (≈10pp worsening) past the dismissed magnitude. `delta_pct` is rounded to 0.1pp before bucketing so floating-point jitter cannot shift a bucket alone.

## Provenance model (frozen concepts)

Three concepts are **distinct**. Do not overload `CareSource` (rhythm provenance on `health_entries`) to represent all three. Never infer one axis from another; capture each at the moment it becomes relevant (progressive contextual capture).

### measurementSource (per weight entry)

Who or what produced **this measurement**? Values: `guardian`, `clinic`, `device`, `imported`. Storage: `weight_entries.measurement_source`. Wire: GET includes default `guardian` for legacy rows; POST/PUT accept optional `measurement_source` / `measurementSource`; invalid → 400.

### referenceAuthority (pet weight reference)

What is the **reference or target** being compared against, and who established it? Values: `vet_target`, `guardian_reference`, `historical_baseline`. Storage: `pets.weight_reference_authority` + `pets.weight_reference_value`. Persist **provenance**, not only the numeric reference.

### managementContext (active weight management)

Is an **intentional management plan** already active for this concern? Values: `none`, `vet_managed`, `care_plan`, `treatment_related`. Storage: `pets.weight_management_context`.

**D0.5 gate:** Before research using production user data — product/governance sign-off on the provenance contract; execute-plan halt `governance_approval_required`. Progressive capture UI ships in parallel micro-PRs; D0 establishes persistence and wire contract only. Code artifacts: [d0-provenance-contract.md](../changes/d0-provenance-contract.md).

## Data-quality gating

Before review-relevance or safeguard logic runs: sufficient measurement **count** and **spacing**; **unit** consistency; documented outlier handling; personal baseline confidence thresholds met. Poor or sparse longitudinal data must not produce high-confidence guardian messaging.

**Weight-only minimum bar (Phase E handoff):** quality classifier `adequate: true`; `WeightChangeSpec` `unexplained_material` with persistent trend; no active `management_context` and no matching `vet_target` reference; ≥3 measurements over ≥14 days (`QUALITY_THRESHOLDS`).

## Evidence and explainability

Internal evaluation and guardian safeguards must be **traceable**: which measurements contributed; which rules fired; which suppression context applied; engine/knowledge version identifiers.

Design-approved persistence types (not all shipped): `CareSignalEvidence`, `CareSafeguard`, ephemeral `PhaseDEvidenceTrace` for research runs. D6 benchmark preserves per-reviewer fields (`reviewerDecision`, `reviewerConfidence`, `reviewerRationale`) and case-level disagreement (`uncertain/reviewer_disagreement` — adjudicated label is one view, not training truth).

**D5a summary (in-repo harness):** Reference vectors cover quality, suppression, unexplained decline, puppy growth; crisp rules sufficient for weight-only Phase D; inadequate data → silence; no diagnosis strings in traces. Harness: `server/routes/careIntelligence/evaluationHarness.js`; run `cd server && npx jest test/careIntelligence/reviewRelevance.test.js`.

All evaluation artifacts that inform production behaviour must live **in-repo** (harness, classifier, specs, tests). Notebooks may explore; they do not define production thresholds without committed code and tests.

## Single-signal guardian copy

When only **one evidence family** (e.g. weight) supports a safeguard:

- Copy must **name that family** explicitly.
- Do **not** use plural language (“several health patterns”, “multiple signals”) unless independent signal families genuinely contributed.

Template (weight-only, when gated):

> "{petName}'s weight has been trending {direction} across several measurements. There isn't a known weight plan recorded, so it may be worth mentioning this to your vet."

## Weight-only safeguards (Phase E)

Permitted without a second longitudinal signal family, subject to a **high bar**: measurement quality adequate; change material and persistent; life-stage explanation does not account for it; no known intentional weight plan; no vet instruction already covers it; **structured context** for the safeguard class exists in production (reference provenance, management context).

**Internal API today:** `GET /api/pets/:id/review-relevance/evaluate` returns `internal_only: true` evaluation + trace. Phase E may promote to guardian-facing safeguard card when D5b gates pass.

## Second signal family (design only)

Candidate ranked families: activity/exercise, appetite, BCS — none have reliable structured longitudinal data today. Multi-signal safeguards require **both** families to pass quality and materiality gates; defer implementation until weight-only Phase E path is evaluated. Activity is the likely first second family if capture UX is validated. See [d4a-second-signal-design.md](../changes/d4a-second-signal-design.md).

## Species scope

- **Suggestions (Phase C):** cats and dogs only; unsupported species must not crash Care Status or rhythms.
- **Safeguards:** follow Phase D/E evaluation scope; do not generalise from cat/dog benchmarks without explicit approval.

## Regulatory and privacy

Benchmark curation, evidence traces, and production safeguard persistence must align with [DATA_MAP.md](/regulatory/DATA_MAP.md) and [INTERNAL_GDPR.md](/regulatory/INTERNAL_GDPR.md). Phase D internal evaluation defaults to **no production user data** until human gates approve otherwise. Update DATA_MAP before persisting `CareSafeguard` or traces beyond ephemeral evaluation.

**Security prerequisite (planned):** Pet Care P0 hardening (private health files, share minimization, capability auth) must land before confident live test with real health data alongside safeguards — see [hardening-discovery.md](../changes/hardening-discovery.md).

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-INTELLIGENCE-R-001 | CIM is not a symptom checker, diagnostic engine, or autonomous care planner | Live |
| CARE-INTELLIGENCE-R-002 | Default is silence; absence of suggestion or safeguard is often correct | Live |
| CARE-INTELLIGENCE-R-003 | Unaccepted suggestions never appear in Actions and never change Care Status | Live |
| CARE-INTELLIGENCE-R-004 | `measurementSource`, `referenceAuthority`, and `managementContext` are orthogonal — never infer one from another | Live |
| CARE-INTELLIGENCE-R-005 | `CareSource` on recurring `health_entries` is rhythm provenance only — not a substitute for weight provenance axes | Live |
| CARE-INTELLIGENCE-R-006 | Review relevance is material persistent change worth mentioning to a vet after ordinary explanations ruled out — not diagnosis or emergency triage | Live |
| CARE-INTELLIGENCE-R-007 | Authority hierarchy: vet instruction beats care plan beats guardian reference beats statistical inference for suppression | Live |
| CARE-INTELLIGENCE-R-008 | Only unexplained material changes are candidates for review-relevance flags or Phase E safeguards | Live |
| CARE-INTELLIGENCE-R-009 | Phase C rhythm suggestions: cats and dogs only; unsupported species must not break Care Status or rhythms | Live |
| CARE-INTELLIGENCE-R-010 | Safeguards are informational — not alarms; suggestions alone cannot change Care Status | Live |
| CARE-INTELLIGENCE-R-011 | Single-signal safeguard copy names the evidence family; no plural patterns/signals unless multiple independent families contributed | Live |
| CARE-INTELLIGENCE-R-012 | Weight-only safeguard allowed only with high bar plus structured weight context fields in production API | Live |
| CARE-INTELLIGENCE-R-013 | Multi-signal production safeguards deferred until a second validated longitudinal signal family exists | Planned |
| CARE-INTELLIGENCE-R-014 | Run data-quality gating before review-relevance or safeguard logic; sparse or poor data yields no high-confidence messaging | Live |
| CARE-INTELLIGENCE-R-015 | CIM cannot override explicit veterinary cadence; `NOT_RELEVANT` and dismiss suppress until context changes materially | Live |
| CARE-INTELLIGENCE-R-016 | Dismissed weight safeguard resurfaces only after ≈10pp worsening (two 5% magnitude buckets) from dismissed magnitude | Live |
| CARE-INTELLIGENCE-R-017 | Phase D review-relevance is internal-only — no production guardian safeguard UI until Phase E gates | Live |
| CARE-INTELLIGENCE-R-018 | Production evaluation thresholds and harness live in-repo with tests — not notebook-only | Live |
| CARE-INTELLIGENCE-R-019 | Phase D research on production user data requires D0.5 governance approval (`governance_approval_required`) | Live |
| CARE-INTELLIGENCE-R-020 | D0 wire: weight entries expose `measurement_source`; pets expose weight reference and management context with partial PUT | Live |
| CARE-INTELLIGENCE-R-021 | Schedule pause/reschedule/skip facts beyond raw occurrences: read `explainGap` from CSM — explained/unexplained vocabulary stays in CIM | Live |
| CARE-INTELLIGENCE-R-022 | Map new safeguard or trace persistence in DATA_MAP before ship | Live |
| CARE-INTELLIGENCE-R-023 | Weight-only Phase E minimum: adequate quality classifier, unexplained_material persistent trend, suppression rules, ≥3 measurements over ≥14 days | Live |
| CARE-INTELLIGENCE-R-024 | Progressive contextual capture at moment of relevance — no standalone clinical configuration screen | Live |
| CARE-INTELLIGENCE-R-025 | No LLM clinical reasoning in production CIM surfaces | Live |
| CARE-INTELLIGENCE-R-026 | Phase E scope lock requires D5b approval (`model_selection_approval_required`) on control issue #1082 | Live |
| CARE-INTELLIGENCE-R-027 | D6 benchmark preserves reviewer disagreement; do not force consensus labels for training | Live |
| CARE-INTELLIGENCE-R-028 | Pet Care P0 security hardening complete before live test with real health data alongside safeguards | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| CIM-1 — When weight series below count threshold then Quality classifier marks inadequate | CARE-INTELLIGENCE-R-014 | test: server/test/careIntelligence/reviewRelevance.test.js |
| CIM-2 — When persistent unexplained decline with adequate series then Review relevance true | CARE-INTELLIGENCE-R-006 | test: server/test/careIntelligence/reviewRelevance.test.js |
| CIM-3 — When evaluation harness runs then Reference vectors and safety regression pass | CARE-INTELLIGENCE-R-018 | test: server/test/careIntelligence/reviewRelevance.test.js |
| CIM-4 — When WeightChangeSpec fixtures run then Materiality and classification match golden cases | CARE-INTELLIGENCE-R-008 | test: server/test/careIntelligence/weightChangeSpec.test.js |
| CIM-5 — When provenance validators run then Orthogonal axes accepted and invalid enums rejected | CARE-INTELLIGENCE-R-004 | test: server/test/careIntelligence/provenance.test.js |
| CIM-6 — When weight safeguard evaluator runs then High bar and suppression respected | CARE-INTELLIGENCE-R-012 | test: server/test/careIntelligence/safeguards.test.js |
| CIM-7 — When rule engine recommendation fixtures run then Suggestions do not alter Care Status | CARE-INTELLIGENCE-R-003 | test: server/test/careIntelligence/recommendations.test.js |
| CIM-8 — When care schedule integration gate runs then CIM rule engine baseline unchanged | CARE-INTELLIGENCE-R-003 | test: server/test/careSchedule/integrationGate.test.js |
| CIM-9 — When suggestion card renders then Copy follows Agatha suggestion patterns | CARE-INTELLIGENCE-R-009 | test: flutter_app/test/features/care_intelligence/presentation/widgets/care_suggestion_card_test.dart |
| CIM-10 — When safeguard card renders then Single-signal copy names weight family | CARE-INTELLIGENCE-R-011 | test: flutter_app/test/features/care_intelligence/presentation/widgets/care_safeguard_card_test.dart |
| CIM-11 — When weight provenance enums parsed then Flutter aligns with server contract | CARE-INTELLIGENCE-R-020 | test: flutter_app/test/features/care_intelligence/weight_provenance_test.dart |
| CIM-12 — When pet profile suggestion section loads then Provider surfaces suggestion state | CARE-INTELLIGENCE-R-009 | test: flutter_app/test/features/care_intelligence/presentation/providers/care_recommendations_provider_test.dart |
| CIM-13 — When guardian sees production safeguard then Presentation respects safeguard-first slot order | CARE-INTELLIGENCE-R-010 | none — #1770 |

Coverage gaps: [#1770](https://github.com/KanopeeKa/AgathaCheck/issues/1770) (safeguard and suggestion E2E on dashboard/profile).

## Still open

- Complete D3 progressive capture widgets in pet profile weight flow before full Phase E persistence.
- `CareSafeguard` table + guardian-facing promotion from internal evaluate endpoint after D5b.
- Second signal family implementation (activity-first candidate) after weight-only evaluation.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-INTELLIGENCE-D-001 | Freeze three non-inferable provenance axes in D0 | Separate rhythm `CareSource` from weight context | Live | 2026-09-08 | D0 |
| CARE-INTELLIGENCE-D-002 | Phase D internal-only until Phase E | No guardian safeguard UI during research | Live | 2026-09-08 | Phase D |
| CARE-INTELLIGENCE-D-003 | Human gate D0.5 before prod user data research | Governance `governance_approval_required` | Live | 2026-09-08 | #1082 |
| CARE-INTELLIGENCE-D-004 | Crisp weight rules sufficient for Phase D scope | D5a harness; defer fuzzy inference | Live | 2026-09-08 | D5a |
| CARE-INTELLIGENCE-D-005 | Proceed to weight-only Phase E when D5a + D6.1 + D0 fields in prod | D5b standing grant per D7 handoff | Live | 2026-09-08 | D7 |
| CARE-INTELLIGENCE-D-006 | Defer multi-signal safeguards | No reliable second longitudinal family | Live | 2026-09-08 | D4a |
| CARE-INTELLIGENCE-D-007 | Single-signal copy must name evidence family | Avoid vague “health pattern” messaging | Live | 2026-09-08 | Phase E |
| CARE-INTELLIGENCE-D-008 | Safeguard resurface uses two 5% bucket crossings | Prevent jitter and nag on minor wobble | Live | 2026-09-08 | Phase E |
| CARE-INTELLIGENCE-D-009 | Benchmark disagreement is first-class | `uncertain/reviewer_disagreement` not erased by adjudication | Live | 2026-09-08 | D6 |
| CARE-INTELLIGENCE-D-010 | Evaluation artifacts in-repo only for production thresholds | Engineering vs notebook rule | Live | 2026-09-08 | Phase D |
| CARE-INTELLIGENCE-D-011 | `PhaseDEvidenceTrace` ephemeral by default | Regulatory minimization until DATA_MAP approval | Live | 2026-09-08 | D0 |
| CARE-INTELLIGENCE-D-012 | CSM supplies schedule facts via `explainGap` only | Avoid overloading CIM with scheduling commands | Live | 2026-09-09 | CSM-13 |
| CARE-INTELLIGENCE-D-013 | Progression does not consume review-relevance output | Domain boundary with care_progression | Live | 2026-09-09 | CP prog |

## Related

| Kind | Link |
|------|------|
| Programme roadmap | [care-foundation-roadmap.md](../changes/care-foundation-roadmap.md) |
| Phase D delivery | [phase-d-review-relevance-plan.md](../changes/phase-d-review-relevance-plan.md) |
| Provenance contract detail | [d0-provenance-contract.md](../changes/d0-provenance-contract.md) |
| Evaluation report | [d5a-evaluation-report.md](../changes/d5a-evaluation-report.md) |
| Phase E handoff | [d7-phase-e-handoff.md](../changes/d7-phase-e-handoff.md) |
| Second signal design | [d4a-second-signal-design.md](../changes/d4a-second-signal-design.md) |
| Security discovery | [hardening-discovery.md](../changes/hardening-discovery.md) |
| Progression | [care-progression.md](./care-progression.md) |
| Scheduling | [care-schedule-management.md](./care-schedule-management.md) |
